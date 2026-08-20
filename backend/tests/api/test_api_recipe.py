def test_recipe_creation(
    user_client_with_household,
    household_id,
    recipe_name,
    recipe_description,
    recipe_yields,
    recipe_time,
):
    """Test creating a recipe"""
    # Create a recipe
    recipe_data = {
        "name": recipe_name,
        "description": recipe_description,
        "yields": recipe_yields,
        "time": recipe_time,
        "items": [],
    }

    response = user_client_with_household.post(
        f"/api/household/{household_id}/recipe", json=recipe_data
    )
    assert response.status_code == 200
    recipe = response.get_json()
    assert "id" in recipe
    recipe_id = recipe["id"]

    # Verify recipe was created correctly
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["name"] == recipe_name
    assert recipe["description"] == recipe_description
    assert recipe["yields"] == recipe_yields
    assert recipe["time"] == recipe_time


def test_recipe_with_items(user_client_with_household, household_id, recipe_with_items):
    """Test recipe with items"""
    recipe_id = recipe_with_items

    # Get recipe and verify it has items
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200
    recipe = response.get_json()
    assert len(recipe["items"]) == 1
    assert recipe["items"][0]["description"] == "2 pieces"


def test_recipe_update(user_client_with_household, recipe_with_items):
    """Test updating a recipe"""
    recipe_id = recipe_with_items

    # Update recipe
    updated_data = {
        "name": "Updated Recipe",
        "description": "Updated description",
        "yields": 6,
        "time": 45,
        "items": [],  # Remove all items
    }

    response = user_client_with_household.post(
        f"/api/recipe/{recipe_id}", json=updated_data
    )
    assert response.status_code == 200

    # Verify updates
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["name"] == "Updated Recipe"
    assert recipe["description"] == "Updated description"
    assert recipe["yields"] == 6
    assert recipe["time"] == 45
    assert len(recipe["items"]) == 0


def test_recipe_search(user_client_with_household, household_id, recipe_with_items):
    """Test searching for recipes"""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe/search?query=Test"
    )
    assert response.status_code == 200
    recipes = response.get_json()
    assert len(recipes) > 0
    assert any(r["id"] == recipe_with_items for r in recipes)


def test_recipe_deletion(user_client_with_household, recipe_with_items):
    """Test deleting a recipe"""
    recipe_id = recipe_with_items

    # Delete recipe
    response = user_client_with_household.delete(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200

    # Verify deletion
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code != 200  # Should not be found


def test_recipe_review_create_update_and_delete(
    user_client_with_household, recipe_with_items
):
    recipe_id = recipe_with_items

    response = user_client_with_household.post(
        f"/api/recipe/{recipe_id}/review",
        json={"rating": 5, "review": "A family favorite."},
    )
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["rating_count"] == 1
    assert recipe["rating_average"] == 5
    assert recipe["my_rating"] == 5
    assert recipe["my_review"] == "A family favorite."
    assert len(recipe["reviews"]) == 1
    assert recipe["reviews"][0]["user"]["username"] == "testuser"

    response = user_client_with_household.post(
        f"/api/recipe/{recipe_id}/review",
        json={"rating": 3, "review": "Still good with less salt."},
    )
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["rating_count"] == 1
    assert recipe["rating_average"] == 3
    assert recipe["my_rating"] == 3

    response = user_client_with_household.delete(f"/api/recipe/{recipe_id}/review")
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["rating_count"] == 0
    assert recipe["rating_average"] == 0
    assert recipe["my_rating"] is None
    assert recipe["reviews"] == []


def test_recipe_review_rejects_invalid_rating(
    user_client_with_household, recipe_with_items
):
    response = user_client_with_household.post(
        f"/api/recipe/{recipe_with_items}/review",
        json={"rating": 6},
    )
    assert response.status_code == 400

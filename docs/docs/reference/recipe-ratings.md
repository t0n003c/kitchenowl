# Recipe ratings and reviews

Recipe ratings and reviews are shared with members of the recipe's household.
Each member can keep one review per recipe and can update or remove it later.

## What is stored

- A rating from 1 to 5 stars
- An optional review of up to 2,000 characters
- The author and creation/update timestamps

The recipe detail view shows the household average, number of ratings, and the
individual reviews. Recipe cards show the average when a recipe has at least
one rating.

## Privacy and access

Only authenticated household members can create, update, delete, or read the
individual reviews. Public recipe discovery may show the aggregate rating, but
it does not expose household review text or member names.

The database migration is applied automatically during the normal KitchenOwl
upgrade process. Existing recipes start with no ratings and are not modified.

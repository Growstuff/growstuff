
## Elastic search

Elasticsearch is used to retrieve data used in many pages. When data is
created, updated, or deleted, and index of this data is saved into elastic
search. This is denormlised data, which for us means it's saved into elastic
search in a structure ready to be displayed onto our pages. Data in postgres,
on the other hand, is saved in a different structure, that ensures data
integrity.

For example, a crop needs a default photo. The photo used is the most "liked"
photo of plantings, seeds or harvests for that crop. To get this from
postgresql you'd need to look up the crops tables, the
plantings,seeds,harvests, the photos, and then the likes. Instead of doing
that on every display of a crop photo, we calculate this at data change and
saved into the Elasticsearch index for crops.

### Installing Elasticsearch

Currently we use elastic search 7. You can check if this is still true by
looking for the `ELASTIC_SEARCH_VERSION` variable in the `.travis.yml` file

To install ES on a debian/ubuntu machine you can use the same script used in
travis-ci:

```
export ELASTIC_SEARCH_VERSION="7.5.1-amd64" ./script/install_elasticsearch.sh
```

You can check that it started happily using:
```
./script/check_elasticsearch.sh
```

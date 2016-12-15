i18n Documentation
===================

i18n Automation
-------------
Automate string extraction from haml into locale files using [haml-i18n-extractor](https://github.com/shaiguitar/haml-i18n-extractor)

```rake i18n:extractor[relative_path_to_view]```


####Example
```rake i18n:extractor[app/views/layouts/_header.html.haml]```

* Creates app/views/layouts/_header.html.i18n-extractor.haml with the expected haml changes to localize app/views/layouts/_header.html.haml. After reviewing the changes, copy app/views/layouts/_header.html.i18n-extractor.haml to app/views/layouts/_header.html.haml
* Adds new keys to locales/en.yml

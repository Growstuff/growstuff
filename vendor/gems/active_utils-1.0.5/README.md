# Active Utils

Active Utils extracts commonly used modules and classes used by [Active Merchant](http://github.com/Shopify/active_merchant), [Active Shipping](http://github.com/Shopify/active_shipping), and [Active Fulfillment](http://github.com/Shopify/active_fulfillment).

### Includes

* Connection - base class for making HTTP requests
* Country - find countries mapped by name, country codes, and numeric values
* Error - common error classes used throughout the Active projects
* PostData - helper class for managing required fields that are to be POST-ed
* PostsData - making SSL HTTP requests
* RequiresParameters - helper method to ensure the required parameters are passed in
* Utils - common utils such as uid generator
* Validateable - module used for making models validateable
* NetworkConnectionRetries - module for retrying network connections when connection errors occur

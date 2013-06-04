# tasks to run at deploy time, usually after 'rake db:migrate'

# When adding tasks, do so in chronological order, and note the date
# when it was added.  This will help us know which ones have been run
# and can safely be commented out or removed.

# echo "2013-05-?? - Replacing empty post/notification subjects with '(no subject)'"
# rake growstuff:oneoff:empty_subjects

# echo "2013-06-03 - replace empty garden names with 'Garden'"
# rake growstuff:oneoff:empty_garden_names

echo "2013-06-04 - set up Paypal API"
echo "You must run:"
echo "  heroku config:set PAYPAL_USERNAME=..."
echo "  heroku config:set PAYPAL_PASSWORD=..."
echo "  heroku config:set PAYPAL_SIGNATURE=..."



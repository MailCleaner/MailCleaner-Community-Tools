## Fix DB and SpamHandler for clustering MailCleaner Community Edition 2014.10 with 2017.xx

#### If you're planning to create cluster with a MailCleaner 2017.xx (or Higher) and a MailCleaner 2014.10, you need to run this script.

This script will recreate all spam_* tables (and the spam merged table) on mc_spool database by adding the is_newsletter column.
It will also modify the SpamHandler in order to handle the newsletter tag.

The Newsletter engine is not present in version 201410 so newsletters detection will not work or partially work (possibly only on 2017 MailCleaner).


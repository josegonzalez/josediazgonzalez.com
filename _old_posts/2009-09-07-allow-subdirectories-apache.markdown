---
  title:       "Allow Subdirectories Apache"
  date:        2009-09-07 00:00
  description: Example .htaccess file for allowing custom subdirectories in your CakePHP application under Apache
  category:    cakephp
  tags:
    - apache
    - cakephp
    - htaccess
    - quicktip
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On

    # Overrides
    RewriteCond %{REQUEST_URI} ^/?(development)/(.*)$
    RewriteRule ^.*$ - [L]

    # Cake rewrites here
    RewriteRule    ^$ app/webroot/    [L]
    RewriteRule    (.*) app/webroot/$1 [L]

</IfModule>
```

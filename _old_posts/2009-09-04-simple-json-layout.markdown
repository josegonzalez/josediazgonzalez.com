---
  title:       "Simple JSON Layout"
  date:        2009-09-04 00:00
  description: Extremely simple JSON Layout for your application
  category:    cakephp
  tags:
    - cakephp
    - json
    - layout
    - quicktip
    - views
  comments:    true
  sharing:     true
  published:   false
  layout:      post
---

```php
header('Pragma: no-cache');
header('Cache-Control: no-store, no-cache, max-age=0, must-revalidate');
header('Content-Type: text/x-json');
echo $content_for_layout;
```

# Kadokadeo

## Configuration

Start by copying `.env.example` into `.env`.

This is an example of Apache config
```
<VirtualHost *:80>
    DocumentRoot "C:\Julien\Sites Web\eternaltwin\kadokadeo\kadokadeo\public"
    ServerName kadokadeo.localhost
    <Directory "C:\Julien\Sites Web\eternaltwin\kadokadeo\kadokadeo\public">
        AllowOverride All
        Require all granted
		FallbackResource /index.php
    </Directory>
</VirtualHost>
```

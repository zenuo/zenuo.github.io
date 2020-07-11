---
layout: post
---

> 在`ArchLinux ARM`上编译`Nginx`及其拓展模块[nginx-dav-ext-module](https://github.com/arut/nginx-dav-ext-module)

下载nginx：

> 在家目录下操作。

```bash
$ curl -O -L https://nginx.org/download/nginx-1.16.0.tar.gz
$ tar zxf nginx-1.16.0.tar.gz
$ cd ~/nginx-1.16.0
```

下载模块`nginx-dav-ext-module`：

```bash
$ mkdir module && cd module
$ git clone https://github.com/arut/nginx-dav-ext-module
```

配置nginx-dav-ext-module：

```bash
$ vim module/nginx-dav-ext-module/config
```

修改：

```diff
diff --git a/config b/config
index 91ae1b3..777f5e9 100644
--- a/config
+++ b/config
@@ -8,9 +8,9 @@ ngx_module_name=ngx_http_dav_ext_module
 # building nginx with the xslt module, in which case libxslt will
 # be linked anyway.  In other cases libxslt is just redundant.
 # If that's a big deal, libxml2 can be linked directly:
-# ngx_module_libs=-lxml2
+ngx_module_libs=-lxml2
 
-ngx_module_libs=LIBXSLT
+# ngx_module_libs=LIBXSLT
 
 ngx_module_srcs="$ngx_addon_dir/ngx_http_dav_ext_module.c"
```

安装`libxml2`和`icu`：

```bash
sudo pacman -S libxml2 icu
```

配置与构建：

```bash
$ cd ~/nginx-1.16.0
$ ./configure \
--with-cc-opt="-I /usr/include/libxml2" \
--with-http_dav_module \
--add-module=module/nginx-dav-ext-module
$ make
```

配置文件`conf/nginx.conf`：

```
server {
    listen       80;
    server_name  localhost;

    location / {
        root   /mnt/disk01;

        autoindex on;
        autoindex_format html;
        autoindex_exact_size off;
        autoindex_localtime on;

        dav_methods PUT DELETE MKCOL COPY MOVE;
        dav_ext_methods PROPFIND OPTIONS;
        dav_access            group:rw  all:r;
        create_full_put_path  on;

        allow 192.168.1.0/24;
        deny all;

        charset utf-8;
        index  index.html index.htm;
    }
}
```

运行nginx：

```
$ sudo ./objs/nginx -p .
```

## 参考

- [configure_gcc](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#configure_gcc)
- [libxml2 2.9.9-2](https://www.archlinux.org/packages/extra/x86_64/libxml2/)
- [arut/nginx-dav-ext-module](https://github.com/arut/nginx-dav-ext-module)
# ProxyExample

Install Ruby with RVM using: `\curl -sSL https://get.rvm.io | bash -s stable --ruby`

Then run `bundle && ruby config.ru` and in another terminal:

```
curl --compressed http://localhost:8000/proxy/http://httpbin.org/get
```
(Note the use of `--compressed`, in the original it might return gzipped data, in this version it passes through that information.)

Or for a POST request:

```
curl --compressed -X POST -d asdf=blah  http://localhost:8000/proxy/http://httpbin.org/post
```

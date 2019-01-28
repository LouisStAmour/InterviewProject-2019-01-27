# ProxyExample

Install Ruby with RVM using:
`\curl -sSL https://get.rvm.io | bash -s stable --ruby`

If on Mac, make sure you have Curl installed using `brew install curl`

Finally, to start the app run `bundle && ruby config.ru` and in another
terminal:

```
curl http://localhost:8000/proxy/http://httpbin.org/get
```

(Note that in the original it might return gzipped data, in this version it
completely ignores Accept-Encoding headers.)

Or for a POST request:

```
curl -X POST -d asdf=blah  http://localhost:8000/proxy/http://httpbin.org/post
```

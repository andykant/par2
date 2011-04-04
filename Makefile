dev: has-coffee
	@coffee -wc --bare -o lib src/
	
test: has-coffee
	@coffee test/par2.coffee
	@test -x par2cmdline/par2
	
par2:
	cd par2cmdline; tar -xf par2cmdline-0.4.tar.gz; patch -p0 < par2cmdline-0.4-gcc4.patch; cd par2cmdline-0.4; ./configure; make && make check; cp -f par2 ../; cd ..; rm -rf par2cmdline-0.4
	@test -x par2cmdline/par2

has-coffee:
	@test `which coffee` || 'You need to install CoffeeScript.'

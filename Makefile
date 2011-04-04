dev: has-coffee
	@coffee -wc --bare -o lib src/
	
test: has-coffee
	@coffee test/par2.coffee

has-coffee:
	@test `which coffee` || 'You need to install CoffeeScript.'

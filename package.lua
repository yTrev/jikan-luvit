return {
  name = 'PinguRBLX/JikanLua',
  version = '1.0',
  description = 'JikanLua is a wrapper for unofficial MAL API, Jikan.',
  tags = {'lua', 'lit', 'luvit', 'myanimelist', 'jikan'},
  license = 'MIT',
  homepage = 'https://github.com/JikanLua',
  dependencies = {
    'creationix/coro-http',
	  'luvit/secure-socket',
  },
  files = {
      '**.lua',
  }
}
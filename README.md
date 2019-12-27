# jikan-luvit

jikan-luvit is a wrapper for unofficial MAL API, Jikan.

## Usage

```lua
    local jikan = require('jikan-luvit')

    jikan:user('yTrev', 'history', 'anime')(function(success, data)
        if success then
            p(data)
        else
            p('Error: ' .. data)
        end
    end)
```

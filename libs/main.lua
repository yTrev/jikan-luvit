--[[
    jikan-luvit

    Jikan: https://jikan.docs.apiary.io/

    <val> = Obrigatory
    (val) = Optional
]]--

--[[
    Usage example:
        local jikan = require('jikan-luvit')
        local user = jikan:user('yTrev', 'history', 'anime')
        user(function(success, data)
            if success then
                p(data)
            else
                p('Error: ' .. data)
            end
        end)

    Or

        jikan:user('yTrev', 'history', 'anime')(function(success, data)
            if success then
                p(data)
            else
                p('Error: ' .. data)
            end
        end)
]]--

local http = require('coro-http')
local json_parse = require('json').parse
local querystring = require('querystring')

-- Constants --
local format = string.format
local concat, remove = table.concat, table.remove
local API_URL = 'https://api.jikan.moe'
local VERSION = 3

local Jikan = {
    _baseURL = format('%s/v%i', API_URL, VERSION)
}

function Jikan:_formatURL(...)
    return format('%s/%s', self._baseURL, concat({...}, '/'))
end

function Jikan:_makeUrl(path, query)
    path = (type(path) == 'string' and path or type(path) == 'table' and concat(path, '/'))
    query = query and querystring.stringify(query) or ''

    return format('%s/%s?%s', self._baseURL, path, query)
end

function Jikan:_assertParam(expected, value)
    local type = type(value)
    if type ~= expected then
        return false
    else
        if type == 'string' and value == '' then
            return false
        elseif type == 'number' and value <= 0 then
            return false
        end
    end

    return true
end

function Jikan:_request(url)
    return coroutine.wrap(function(callback)
        local res, body = http.request('GET', url)
        if res.code == 200 then
            callback(true, json_parse(body))
        else
            callback(false, res)
        end
    end)
end

function Jikan:_get(type, ...)
    local request = self:_request(self:_formatURL(type, ...))

    return request
end

--[[
    version(<version>)
        version | integer

    Ex:
        version(2)
]]

function Jikan:version(version)
    assert(type(version) == 'number' and version > 0, 'Invalid version.')
    self._baseURL = format('%s/v%i', API_URL, version)
end

--[[
    anime(<id>, (request), (parameter))
        id | integer
        request | string: https://jikan.docs.apiary.io/#reference/0/anime
        parameter | integer

    return coroutine

    Ex:
        anime(20507)
        anime(20507, 'episodes')
        anime(20507, 'reviews', 2)
]]--
function Jikan:anime(id, request, parameter)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('anime', id, request, parameter)
end

--[[
    manga(<id>, (request), (parameter))
        id | integer
        request | string: https://jikan.docs.apiary.io/#reference/0/manga
        parameter | integer

    return coroutine

    Ex:
        manga(74341)
        manga(74341, 'characters')
        manga(74341, 'reviews', 2)
]]--
function Jikan:manga(id, request, parameter)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('manga', id, request, parameter)
end

--[[
    person(<id>, (request))
        id      | integer
        request | string

    return coroutine

    Ex:
        person(1, 'pictures')
]]--
function Jikan:person(id, request)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('person', id, request)
end

--[[
    character(<id>, (request))
        id      | integer
        request | string

    return coroutine

    Ex:
        character(84677, 'pictures')
        character(84677)
        character(84679)
]]--
function Jikan:character(id, request)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('character', id, request)
end

--[[
    search(<type>, (params))
        type | anime, manga, person, character
        params | https://jikan.docs.apiary.io/#reference/0/search

    return coroutine

    Ex:
        search('anime', {q = 'Kimetsu', sort = 'descending', order_by = 'score'})
        search('manga', {q = 'Naruto'})
]]--
function Jikan:search(ty, params)
    assert(ty)
    assert(type(params) == 'table', format('Expected a table, but got a %s', type(params)))

    if params.q and not (#params.q >= 3) then
        error('MyAnimeList only processes queries with a minimum of 3 letters.')
    end

    return self:_request(self:_makeUrl({'search', ty}, params))
end

--[[
    season(<year>, <season>)
        year    | integer
        season  | summer, spring, fall, winter

    return coroutine

    Ex:
        season(2019, 'summer')
]]--
function Jikan:season(year, season)
    assert(year and season, 'Year and season are required!')
    return self:_get('season', year, season)
end

--[[
    seasonArchive()

    return coroutine
]]--
function Jikan:seasonArchive()
    return self:_get('season', 'archive')
end

--[[
    seasonLater()

    return coroutine
]]--
function Jikan:seasonLater()
    return self:_get('season', 'later')
end

--[[
    schedule((day))
        day | monday, tuesday, wednesday, thursday, friday, saturday, sunday, other(v3), unknown(v3)

    return coroutine
]]--
function Jikan:schedule(day)
    return self:_get('schedule', day)
end

--[[
    top(<type>, (page), (subtype))
        type    | anime, manga, people(v3+), characters(v3+);
        page    | integer
        subtype | Anime: airing upcoming tv movie ova special \ Manga: manga novels oneshots doujin manhwa manhua \ Both: bypopularity favorite

    return coroutine
]]--

function Jikan:top(type, page, subtype)
    assert(type)
    return self:_get('top', type, page, subtype)
end

--[[
    genre(<type>, <genre_id>, (page))
        type        | anime, manga;
        genre_id    | integer
        page

    return coroutine
]]--
function Jikan:genre(type, genre_id, page)
    assert(type and genre_id)
    return self:_get('genre', type, genre_id, page)
end

--[[
    producer(<producer_id>, (page))
        producer_id | integer
        page

    return coroutine
]]--
function Jikan:producer(producer_id, page)
    assert(producer_id)
    return self:_get('producer', producer_id, page)
end

--[[
    magazine(<magazine_id>, (page))
        magazine_id | integer
        page

    return coroutine
]]--
function Jikan:magazine(magazine_id, page)
    assert(magazine_id)
    return self:_get('magazine', magazine_id, page)
end

--[[
    user(<username>, <request>, (data))

        username | string
        request | string
        data | string/table

    return coroutine

    Ex:
        user('yTrev', 'animelist', 'all', {q = 'Kimetsu no Yaiba'})
        user('yTrev', 'animelist', {sort = 'descending', order_by = 'score'})
        user('yTrev', 'profile')
        user('yTrev', 'history', 'anime')
]]--
function Jikan:user(...)
    local info = {...}
    assert(info[1] and info[2])

    local data
    table.insert(info, 1, 'user')

    for i = 1, #info do
        if type(info[i]) == 'table' then
            data = remove(info, i)
            break
        end
    end

    return self:_request(self:_makeUrl(info, data))
end

--[[
    club(<id>)
        id | integer

    return coroutine
    Ex:
        club(5)
]]--
function Jikan:club(id)
    assert(id)

    return self:_get('club', id)
end

--[[
    clubMember(<id>, <page>)
        id  | integer

    return coroutine
]]--
function Jikan:clubMember(id, page)
    assert(id and page)
    return self:_get('club', id, 'members', page)
end

--[[
    meta(<type>, <period>, <offset>)
        type    |  anime, manga, character, person, search, top, schedule, season
        period  | today weekly monthly
        int     |

    return coroutine
]]--
function Jikan:meta(type, period, offset)
    return self:_get('meta', 'requests', type, period, offset)
end

--[[
    status()
]]--
function Jikan:status()
    return self:_get('meta', 'status')
end

return Jikan
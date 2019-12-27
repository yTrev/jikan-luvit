--[[
    JikanLua

    Jikan: https://jikan.docs.apiary.io/

    <val> = Obrigatory
    (val) = Optional
]]--

--[[
    Usage example:
        local JikanLua = require('jikanlua')
        local user = JikanLua:User('yTrev', 'history', 'anime')
        user(function(success, data)
            if success then
                p(data)
            else
                p('Error: ' .. data)
            end
        end)

        Or

        JikanLua:User('yTrev', 'history', 'anime')(function(success, data)
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

function Jikan:Version(version)
    assert(type(version) == 'number' and version > 0, 'Invalid version.')
    self._baseURL = format('%s/v%i', API_URL, version)
end

--[[
    Anime(<id>, (request), (parameter))
        id | integer
        request | string: https://jikan.docs.apiary.io/#reference/0/anime
        parameter | integer

    return coroutine

    Ex:
        Anime(20507)
        Anime(20507, 'episodes')
        Anime(20507, 'reviews', 2)
]]--
function Jikan:Anime(id, request, parameter)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('anime', id, request, parameter)
end

--[[
    Manga(<id>, (request), (parameter))
        id | integer
        request | string: https://jikan.docs.apiary.io/#reference/0/manga
        parameter | integer

    return coroutine

    Ex:
        Manga(74341)
        Manga(74341, 'characters')
        Manga(74341, 'reviews', 2)
]]--
function Jikan:Manga(id, request, parameter)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('manga', id, request, parameter)
end

--[[
    Person(<id>, (request))
        id      | integer
        request | string

    return coroutine

    Ex:
        Person(1, 'pictures')
]]--
function Jikan:Person(id, request)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('person', id, request)
end

--[[
    Character(<id>, (request))
        id      | integer
        request | string

    return coroutine

    Ex:
        Character(84677, 'pictures')
        Character(84677)
        Character(84679)
]]--
function Jikan:Character(id, request)
    assert(type(id) == 'number', format('Expected a number, but got a %s', type(id)))
    return self:_get('character', id, request)
end

--[[
    Search(<type>, (params))
        type | anime, manga, person, character
        params | https://jikan.docs.apiary.io/#reference/0/search

    return coroutine

    Ex:
        Search('anime', {q = 'Kimetsu', sort = 'descending', order_by = 'score'})
        Search('manga', {q = 'Naruto'})
]]--
function Jikan:Search(ty, params)
    assert(ty)
    assert(type(params) == 'table', format('Expected a table, but got a %s', type(params)))

    if params.q and not (#params.q >= 3) then
        error('MyAnimeList only processes queries with a minimum of 3 letters.')
    end

    return self:_request(self:_makeUrl({'search', ty}, params))
end

--[[
    Season(<year>, <season>)
        year    | integer
        season  | summer, spring, fall, winter

    return coroutine

    Ex:
        Season(2019, 'summer')
]]--
function Jikan:Season(year, season)
    assert(year and season, 'Year and season are required!')
    return self:_get('season', year, season)
end

--[[
    SeasonArchive()

    return coroutine
]]--
function Jikan:SeasonArchive()
    return self:_get('season', 'archive')
end

--[[
    SeasonLater()

    return coroutine
]]--
function Jikan:SeasonLater()
    return self:_get('season', 'later')
end

--[[
    SeasonLater((day))
        day | monday, tuesday, wednesday, thursday, friday, saturday, sunday, other(v3), unknown(v3)

    return coroutine
]]--
function Jikan:Schedule(day)
    return self:_get('schedule', day)
end

--[[
    Top(<type>, (page), (subtype))
        type    | anime, manga, people(v3+), characters(v3+);
        page    | integer
        subtype | Anime: airing upcoming tv movie ova special \ Manga: manga novels oneshots doujin manhwa manhua \ Both: bypopularity favorite

    return coroutine
]]--

function Jikan:Top(type, page, subtype)
    assert(type)
    return self:_get('top', type, page, subtype)
end

--[[
    Genre(<type>, <genre_id>, (page))
        type        | anime, manga;
        genre_id    | integer
        page
    
    return coroutine
]]--
function Jikan:Genre(type, genre_id, page)
    assert(type and genre_id)
    return self:_get('genre', type, genre_id, page)
end

--[[
    Producer(<producer_id>, (page))
        producer_id | integer
        page
    
    return coroutine
]]--
function Jikan:Producer(producer_id, page)
    assert(producer_id)
    return self:_get('producer', producer_id, page)
end

--[[
    Magazine(<magazine_id>, (page))
        magazine_id | integer
        page
    
    return coroutine
]]--
function Jikan:Magazine(magazine_id, page)
    assert(magazine_id)
    return self:_get('magazine', magazine_id, page)
end

--[[
    User(<username>, <request>, (data))

        username | string
        request | string
        data | string/table

    return coroutine

    Ex:
        User('yTrev', 'animelist', 'all', {q = 'Kimetsu no Yaiba'})
        User('yTrev', 'animelist', {sort = 'descending', order_by = 'score'})
        User('yTrev', 'profile')
        User('yTrev', 'history', 'anime')
]]--
function Jikan:User(...)
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
    Club(<id>)
        id | integer

    return coroutine
    Ex:
        Club(5)
]]--
function Jikan:Club(id)
    assert(id)

    return self:_get('club', id)
end

--[[
    ClubMember(<id>, <page>)
        id  | integer

    return coroutine
]]--
function Jikan:ClubMember(id, page)
    assert(id and page)
    return self:_get('club', id, 'members', page)
end

--[[
    Meta(<type>, <period>, <offset>)
        type    |  anime, manga, character, person, search, top, schedule, season
        period  | today weekly monthly
        int     |

    return coroutine
]]--
function Jikan:Meta(type, period, offset)
    return self:_get('meta', 'requests', type, period, offset)
end

--[[
    Status()
]]--
function Jikan:Status()
    return self:_get('meta', 'status')
end

return Jikan
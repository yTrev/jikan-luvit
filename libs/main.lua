--[[
    JikanLua

    Jikan: https://jikan.docs.apiary.io/

    <val> = Obrigatory
    (val) = Optional
]]--

--[[
    Usage example:
        local JikanLua = Jikan.new()
        JikanLua:User('yTrev', 'history', 'anime'):thenCall(function(data) --> I don't know how to do this without promises. OTL
            p(data)
        end):catch(function(error)
            p(error)
        end)
]]--

local http = require('coro-http')
local promise = require('promise')
local json_parse = require('json').parse
local URL = require('URL')

-- Constants --
local format = string.format
local concat, remove = table.concat, table.remove

local Jikan = {}
Jikan.__index = Jikan

function Jikan.new()
    local self = setmetatable({}, Jikan)
    self._apiURL = 'https://api.jikan.moe'
    self._version = 3

    self._baseURL = format('%s/v%i', self._apiURL, self._version)

    return self
end

function Jikan:_formatURL(...)
    p(self._baseURL)
    return format('%s/%s', self._baseURL, concat({...}, '/'))
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
    local newPromise = promise.new(function(resolve, reject)
        local chunks = ''

        coroutine.wrap(function()
            local res, body = http.request('GET', url)

            if res.code == 200 then
                resolve(json_parse(body))
            else
                reject(res)
            end
        end)()
    end)

    return newPromise
end

function Jikan:_get(type, ...)
    local request = self:_request(self:_formatURL(type, ...))

    return request
end

--[[
    Anime(<id>, (request), (parameter))
        id | integer
        request | string: https://jikan.docs.apiary.io/#reference/0/anime
        parameter | integer

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

    Ex:
        Search('anime', {q = 'Kimetsu', sort = 'descending', order_by = 'score'})
        Search('manga', {q = 'Naruto'})
]]--
function Jikan:Search(type_, params)
    assert(type_)
    assert(type(params) == 'table', format('Expected a table, but got a %s', type(params)))
    local baseUrl = URL.parse(self:_formatURL('search', type_))

    if params.q and not (#params.q >= 3) then
        error('MyAnimeList only processes queries with a minimum of 3 letters.')
    end

    baseUrl:setQuery(params)

    return self:_request(tostring(baseUrl))
end

--[[
    Season(<year>, <season>)
        year    | integer
        season  | summer, spring, fall, winter

    Ex:
        Season(2019, 'summer')
]]--
function Jikan:Season(year, season)
    assert(year and season, 'Year and season are required!')
    return self:_get('season', year, season)
end

--[[
    SeasonArchive()
]]--
function Jikan:SeasonArchive()
    return self:_get('season', 'archive')
end

--[[
    SeasonLater()
]]--
function Jikan:SeasonLater()
    return self:_get('season', 'later')
end

--[[
    SeasonLater((day))
        day | monday, tuesday, wednesday, thursday, friday, saturday, sunday, other(v3), unknown(v3)
]]--
function Jikan:Schedule(day)
    return self:_get('schedule', day)
end

--[[
    Top(<type>, (page), (subtype))
        type    | anime, manga, people(v3+), characters(v3+);
        page    | integer
        subtype | Anime: airing upcoming tv movie ova special \ Manga: manga novels oneshots doujin manhwa manhua \ Both: bypopularity favorite
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
]]--
function Jikan:Genre(type, genre_id, page)
    assert(type and genre_id)
    return self:_get('genre', type, genre_id, page)
end

--[[
    Producer(<producer_id>, (page))
        producer_id | integer
        page
]]--
function Jikan:Producer(producer_id, page)
    assert(producer_id)
    return self:_get('producer', producer_id, page)
end

--[[
    Magazine(<magazine_id>, (page))
        magazine_id | integer
        page
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

    Ex:
        User('yTrev', 'animelist', 'all', {q = 'Kimetsu no Yaiba'})
        User('yTrev', 'animelist', {sort = 'descending', order_by = 'score'})
        User('yTrev', 'profile')
        User('yTrev', 'history', 'anime')
]]--
function Jikan:User(username, request, ...)
    assert(username and request)
    local extraInfo = {...}
    local data
    for i = 1, #extraInfo do
        if type(extraInfo[i]) == 'table' then
            data = remove(extraInfo, i)
            break
        end
    end

    local baseUrl = URL.parse(self:_formatURL('user', username, request, table.unpack(extraInfo)))

    if data and type(data) == 'table' then
        baseUrl:setQuery(data)
    end

    return self:_request(tostring(baseUrl))
end

--[[
    Club(<id>)
        id | integer

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
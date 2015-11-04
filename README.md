HOST: http://ds-babel.herokuapp.com

# Babel
A translation layer for Diamond Scheduler and various third-party APIs.


## GET /league_athletics/seasons

Pull League Athletics season data.

+ Parameters
    + email (required, string) ... League Athletics account email
    + password (required, string) ... League Athletics account password
    + org (required, string) ... League Athletics organization

+ Response 200 (application/json)

```js
[
  {
    "id": 9292,
    "name": "2013 Summer League",
    "start": "2013-01-03T07:00:00.000Z",
    "finish": "2014-01-01T07:00:00.000Z",
    "team_count": 15
  }
]
```

## POST /league_athletics/pull

Pull League Athletics data to Diamond Scheduler JSON format. Supports
division, venues, and teams.

+ Parameters
    + email (required, string) ... League Athletics account email
    + password (required, string) ... League Athletics account password
    + org (required, string) ... League Athletics organization
    + season_id (required, integer) ... League Athletics season id

+ Response 200 (application/json)

```js
// Diamond Scheduler JSON Export Format
{
  "version_number": "7.0.1",
  "build_number": "0.0.732",
  "league_external_id": "-1",
  "created_at": "Sat May 31 11:00:22 GMT-0700 2014",
  "created_at_timestamp": "1401559221879",
  "league": {
    "divisions": [..],
    "venues": [..],
    "persons": [..],
    "events": [..]
  }
}
```

+ Response 400 (application/json)

```js
{
  "error": "Parameter `season_id` is required"
}
```

+ Response 400 (application/json)

```js
{
  "error": "League Athletics account has 0 seasons"
}
```

+ Response 400 (application/json)

```js
{
  "error": "Season with id `123` not found"
}
```

## GET /teamsnap/sports

A list of TeamSnap sport categories.

+ Response 200 (application/json)

```js
{
  "sports": [
    {
      "id": 59,
      "name": "Archery"
    },
    {
      "id": 26,
      "name": "Australian Football"
    },
    {
      ...
    },
  ]
}
```

## GET /teamsnap/time_zones

A list of TeamSnap supported time zones.

+ Response 200 (application/json)

```js
{
  "time_zones": [
    {
      name: "Eastern Time (US & Canada)",
      description: "(GMT-05:00) Eastern Time (US & Canada)"
    },
    {
      ...
    },
  ]
}
```

## POST /teamsnap/push

Push Diamond Scheduler data to TeamSnap.

+ Parameters
    + email (required, string) ... TeamSnap account email
    + password (required, string) ... TeamSnap account password
    + time_zone (required, string) ... TeamSnap recognized time zone
    + sport_id  (required, integer) ... TeamSnap recognized sport id
    + zip_code (required, string) ... Postal code for all teams
    + country  (optional, string) ... Country, defaults to 'United States'

+ Request Diamond Scheduler JSON Export Format (application/json)

    + Body

        ```js
        // Diamond Scheduler JSON Export Format
        {
          "version_number": "7.0.1",
          "build_number": "0.0.732",
          "league_external_id": "-1",
          "created_at": "Sat May 31 11:00:21 GMT-0700 2014",
          "created_at_timestamp": "1401559221879",
          "league": {
            "divisions": [..],
            "venues": [..],
            "persons": [..],
            "events": [..]
          }
        }
        ```

+ Response 200 (application/json)

```js
// Diamond Scheduler JSON Export Format
{
  "version_number": "7.0.1",
  "build_number": "0.0.732",
  "league_external_id": "-1",
  "created_at": "Sat May 31 11:00:21 GMT-0700 2014",
  "created_at_timestamp": "1401559221879",
  "league": {
    "divisions": [..],
    "venues": [..],
    "persons": [..],
    "events": [..]
  }
}
```

## POST /teamsnap/pull

Pull TeamSnap data to Diamond Scheduler JSON format. Only supports
division, venues, and teams.

+ Parameters
    + email (required, string) ... TeamSnap account email
    + password (required, string) ... TeamSnap account password

+ Response 200 (application/json)

```js
// Diamond Scheduler JSON Export Format
{
  "version_number": "7.0.1",
  "build_number": "0.0.732",
  "league_external_id": "-1",
  "created_at": "Sat May 31 11:00:22 GMT-0700 2014",
  "created_at_timestamp": "1401559221879",
  "league": {
    "divisions": [..],
    "venues": [..],
    "persons": [..],
    "events": [..]
  }
}
```

# elm-horizon
Thin wrapper around Horizon JavaScript client API for writing Horizon application in Elm.

## Collection API

### Write Operation
Write operation includes:
#### `insertCmd`
Insert a new data into a collection.

##### Parameters:
- `collectionName : String`
The name of the Horizon collection
- `values : List Json.Value`
List of encoded Json.Value you want to insert to the collection.

##### Example:
```elm
insertCmd "chat_messages" [ chatMessageEncoder { from = "elm", message = "Hello World!" } ]  
``` 

#### `insertSub`
- ``

#### `replaceCmd/Sub`
#### `updateCmd/Sub`
#### `storeCmd/Sub`
#### `upsertCmd/Sub`
#### `removeCmd/Sub`
#### `removeAllCmd/Sub`

## Authentication
TBA

## Users & Groups
TBA

## Permissions
TBA


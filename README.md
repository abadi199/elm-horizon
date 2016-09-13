# elm-horizon

![Elm & Horizon Logo](images/logo.png "Elm & Horizon Logo")

Thin wrapper around Horizon JavaScript client API for writing Horizon application in Elm.

## Collection API

### Write Operation
#### `insertCmd/replaceCmd/storeCmd/updateCmd/upsertCmd/removeAllCmd`
`*Cmd -> String -> List Json.Value -> Cmd msg`

Insert / replace / store / update / upsert / remove one or more new documents into a Collection.

##### Parameters:
 * `collectionName` is the name of the Horizon collection
 * `values` is List of encoded Json.Value you want to insert / replace / store / update / upsert / remove to the collection.

##### Example:
```elm
insertCmd "chat_messages" [ chatMessageEncoder { id = 1, from = "elm", message = "Hello World!" } ]  
removeAllCmd "chat_messages" <| List.map Json.Encode.int [ 1, 2, 3 ]
``` 
#### `removeCmd`
`removeCmd -> String -> Json.Value -> Cmd msg`

##### Parameters:
 * `collectionName` is the name of the Horizon collection
 * `value` is the encoded Json.Value of the id/record of the data you want to delete.

##### Example:
```elm
removeCmd "chat_messages" <| Json.Encode.int 1
``` 

#### `insertSub/replaceSub/storeSub/updateSub/upsertSub/removeAllSub/removeSub`
`*Sub -> (Result Error () -> msg) -> Sub msg`

Subscription for the result of Insert / replace / store / update / upsert / remove operation.

##### Parameters:
 * `tagger` is the constructor for your msg that requires a `Result`

##### Example:
```elm
type Msg = InsertResponse (Result Error ())

subscriptions = insertSub InsertResponse 
```

### Read Operations

#### `fetchCmd/watchCmd`
`*Cmd -> String -> List Modifier -> Cmd msg`

##### Parameters:
 * `collectionName` is the name of the Horizon collection
 * `modifiers` is the List of Modifier

##### Example:
```elm
watchCmd "chat_messages" [ Limit 10, Order "name" Ascending ]
```

#### `fetchSub/watchSub`
`*Sub -> Decoder a -> (Result Error (List (Maybe a)) -> msg) -> Sub msg`

##### Parameters:
 * `decoder` is the decoder for decoding the data
 * `tagger` is msg constructor for tagging the decoded data

##### Example:
```elm
type Msg = NewMessageMsg (Result Error (List (Maybe ChatMessage)))

subscriptions = watchSub NewMessageMsg
```

### Modifiers
#### `Above Json.Value`
Restrict the range of results returned to values that sort above a given value.

##### Example: 
```elm
Above <| encoder { price = 100.0 }
```

#### `Below Json.Value`
Restrict the range of results returned to values that sort below a given value.

##### Example: 
```elm
Below <| encoder { value = 20 }
```

#### `Find Json.Value`
Retrieve a single document from a Collection.

##### Example: 
```elm
Find <| encoder { id = 1 }
```

#### `FindAll (List Json.Value)`
Retrieve multiple documents from a Collection.

##### Example: 
```elm
FindAll [ encoder { id = 1 }, encoder { id = 2 }]
```

#### `Limit Int`
##### Example: 
```elm
Limit 10
```

#### `Order String Direction`
where `Direction` can be:
 * `Ascending`
 * `Descending`
##### Example: 
```elm
Order "timestamp" Ascending
```

### Examples:
 * [Chat App Example](examples/Chat.elm "Chat App Example")
 * [Search App Example](examples/Search.elm "Search App Example")

## Authentication
TBA

## Users & Groups
TBA

## Permissions
TBA


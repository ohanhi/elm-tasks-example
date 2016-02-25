module Main where

import Time
import Task
import Http
import Html exposing (..)
import Html.Attributes exposing (..)


{-
Example of simple chaining of Tasks. `simpleGet` ignores the resulting value that came from the previous step.
-}
checkFilesAvailableTask : a -> Task.Task Http.Error String
checkFilesAvailableTask _ =
  Http.getString "/index.html"
    `Task.andThen` simpleGet "/LICENSE"
    `Task.andThen` simpleGet "/package.json"
    `Task.andThen` simpleGet "/README.md"


{-
The signal from this mailbox will be the "input" for our app UI.
-}
responses : Signal.Mailbox (Result a String)
responses =
  Signal.mailbox (Ok "Let's assume the best")


{-
For every update on the `timer` signal, we perform the
`checkFilesAvailableTask` and put the results in the `responses`.
-}
port requests : Signal (Task.Task Http.Error ())
port requests =
  Signal.map checkFilesAvailableTask timer
  |> Signal.map putInResponses


{-
Convert Task to a Result (which is either Ok or Err),
then send it to the `responses`.
-}
putInResponses : Task.Task a String -> Task.Task b ()
putInResponses task =
  Task.toResult task
    `Task.andThen` Signal.send responses.address


{-
Simple UI for showing the state of things.
-}
view : Result a b -> Html
view result =
  let (color, contents) = colorAndTextFor result
  in  div [ styles color ] [ text contents ]


{-
Nothing but mapping the view function over our input.
-}
main : Signal Html
main =
  Signal.map view responses.signal


{-
Used for invoking the `requests`.
-}
timer : Signal Time.Time
timer =
  Time.every Time.second


-- HELPERS
simpleGet : String -> a -> Task.Task Http.Error String
simpleGet url _ =
  Http.getString url


styles : String -> List Html.Attribute
styles color =
  style
    [ ("background", color)
    , ("position", "absolute")
    , ("height", "100%")
    , ("width", "100%")
    ]


colorAndTextFor : Result a b -> (String, String)
colorAndTextFor result =
  case result of
    Ok _ ->
      ("#9f9", "All good")
    Err _ ->
      ("#f99", "You're offline or some files are missing")

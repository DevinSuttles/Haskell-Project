-- TODO: Disco / rave mode
-- TODO: Boomer mode
-- TODO: Select ball type
-- TODO: make width, height & offset a float (?)
-- TODO: add pause / unpause

-- TODO: multiply the ball velocity upon wall / paddle collision
-- TODO: change direction of ball upon wall / paddle collision (?)

-- TODO: limit ball velocity (?)

-- TODO: alternate ball color ?

module Main(main) where

import Graphics.Gloss
import Graphics.Gloss.Data.ViewPort
import Graphics.Gloss.Interface.Pure.Game

width, height, offset :: Int
width = 800 -- actual window demension
height = 600 -- actual window demension
offset = 100 -- where does the window populate onto the computer screen

window :: Display -- window properties
window = InWindow "Bouncing Betty" (width, height) (offset, offset)

background :: Color -- background properties
background = black

fps :: Int
fps = 60

-- current game value
-- use game to type check the values passed into PongGame
data PongGame = Game {
  ballLocation :: (Float,Float),
  ballVelocity :: (Float, Float),
  player :: Float
} deriving Show -- so we can read from this structure

-- initial game values
initState :: PongGame
initState = Game {
  ballLocation = (0,0),
  ballVelocity = (150, -300),
  player = 0
}

type Quad = (Float,Float,Float,Float)

-- take the PongGame and create a picture(static image) with it
-- this function is to be used constantly to refresh the current game, ball, and player's pad
-- ??? why do we take player current_game instead of current_game player ???
render :: PongGame -> Picture
render current_game = pictures [ball, walls, mkPaddle white 280 (player current_game) 90]
  where
    -- ball props
    ball =  uncurry translate (ballLocation current_game) (color $ (myColor 214 40 40 40) $ circleSolid 10)
    -- ball = uncurry translate (ballLocation current_game) $ color ballColor $ circleSolid 10
    -- translate float(?) float(?) picture(circleSolid 10)

    --  Top and side walls.
    wall :: Float -> Float -> Float -> Float -> Picture
    wall x y rot length =
      rotate rot $
        translate x y $
          color wallColor $
            rectangleSolid length 10

    myColor :: Quad -> Color
    myColor = makeColor8 x y z a

    wallColor = white
    walls = pictures [wall 0 290 0 790, wall 0 390 90 590, wall 0 (-390) 90 590]

    --  Make a paddle of a given border and vertical offset.
    mkPaddle :: Color -> Float -> Float -> Float -> Picture
    mkPaddle col x y rot = pictures
      [ rotate rot $ translate x y $ color col $ rectangleSolid 26 106,
        rotate rot $ translate x y $ color col $ rectangleSolid 20 100
      ]

moveBall :: Float -> PongGame -> PongGame
-- executes where before we return the new ball location coords
moveBall timePassed current_game = current_game { ballLocation = (x',y') }
  where
    (x, y) = ballLocation current_game
    (xVol, yVol) = ballVelocity current_game
    x' = x + xVol * timePassed
    y' = y + yVol * timePassed


main :: IO ()
main = play window background fps initState render handleKeys update

-- update the game
update :: Float -> PongGame -> PongGame
update timePassed final_game =
  if (outOfBounds final_game')
    then do
      stopBall final_game'
    else
      final_game'

  where final_game' = checkPaddleCollision . checkWallCollision . moveBall timePassed $ final_game

outOfBounds :: PongGame -> Bool
outOfBounds current_game = belowPaddle
  where
    (_, yPos) = ballLocation current_game
    belowPaddle = yPos <= -300

stopBall :: PongGame -> PongGame
stopBall current_game = current_game { ballVelocity = (0, 0) }

handleKeys :: Event -> PongGame -> PongGame
handleKeys (EventKey (Char 'r') _ _ _) current_game = current_game { ballLocation = (0,0) }
handleKeys (EventKey (SpecialKey KeyLeft) _ _ _) current_game =  current_game {player = player current_game - 15}
handleKeys (EventKey (SpecialKey KeyRight) _ _ _) current_game = current_game {player = player current_game + 15}
handleKeys _ current_game = current_game

-- ~~ collision detection ~~

type Radius = Float
type Position = (Float, Float)

heightCollision :: Position -> Radius -> Bool
heightCollision (_, y) radius = topCollision
  where
    topCollision = y + radius >= 300 - 15

widthCollision :: Position -> Radius -> Bool
widthCollision (x, _) radius = leftCollision || rightCollision
  where
    -- leftCollision = x - radius >= -fromIntegral height
    -- rightCollision = x + radius >= fromIntegral height 
    leftCollision = x - radius <= -400 + 15
    rightCollision = x + radius >= 400 - 15

checkWallCollision :: PongGame -> PongGame
-- we already know where the walls are placed ... 
-- find out if ball hits the walls and if collision detected so adjust ball trajectory
checkWallCollision current_game = current_game { ballVelocity = (xVol', yVol')}
  where
    radius = 10
    (xVol, yVol) = ballVelocity current_game

    xVol' = if widthCollision (ballLocation current_game) radius
            then
              -xVol*1.05
            else
              xVol
    yVol' = if heightCollision (ballLocation current_game) radius
            then
              -yVol*1.05
            else
              yVol

paddleCollision :: Position -> Radius -> PongGame -> Bool
paddleCollision (x, y) radius current_game = collision
  where
    radius = 10
    currX = player current_game
    collision = ((y - radius <= (-300 + 29) && (y - radius >= -300))) && ((abs(x - currX) < 53))

checkPaddleCollision :: PongGame -> PongGame
-- take in a current PG and output the new PG
-- find out where the ball is, where the paddle is, adjust ball location upon collision
checkPaddleCollision current_game = current_game {ballVelocity = (xVol, yVol')}
  where
    radius = 10
    (xVol, yVol) = ballVelocity current_game

    yVol' = if paddleCollision (ballLocation current_game) radius current_game
            then
              -yVol*1.05
            else
              yVol

shout :: IO ()
shout = putStrLn "hello"
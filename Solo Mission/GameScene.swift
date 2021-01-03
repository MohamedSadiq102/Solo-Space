//
//  GameScene.swift
//  Solo Mission
//
//  Created by Mohamedsadiq on 26.12.20.
//

import SpriteKit
//import GameplayKit
//import GameOverScene

var gameScore = 0

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    let scoreLabel = SKLabelNode(fontNamed: "theboldfont")
    
    var liveNumber = 3
    let liveLabel = SKLabelNode(fontNamed: "theboldfont")
    
    
    var levelNumber = 0
    
    let player = SKSpriteNode(imageNamed: "playerShip")
    
    let tapToStartLabel = SKLabelNode(fontNamed: "theboldfont")
    
    // 0 -> before a Game, 1 -> During a Game, 2 -> After the Game
    enum gameState {
        case PreGame
        case inGame
        case afterGame
    }
    
    var currentGameState = gameState.PreGame
    
    
//    let bullet = SKSpriteNode(imageNamed: "bullet")
    
    let explosionSound = SKAction.playSoundFileNamed("Bomb+1.wav", waitForCompletion: false)

    let bulletSound = SKAction.playSoundFileNamed("scifi002.wav", waitForCompletion: false)
    
    struct PhysicsCategories {
        static let None : UInt32 = 0
        static let player : UInt32 = 0b1  //binary for 1
        static let Bullet : UInt32 = 0b10 //binary for 2
        static let Enemy  : UInt32 = 0b100 //binary for 4  player & bullet
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    var gameArea: CGRect
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)

        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView){
        
        gameScore = 0
        
        self.physicsWorld.contactDelegate = self
        
        for i in 0...1 {
        
        let background = SKSpriteNode(imageNamed: "background")
        background.size = self.size
        background.anchorPoint = CGPoint(x: 0.5, y: 0)
        // when the i = 0, the foto will be buttom of the screen, when 1 at the up of the screen
        background.position = CGPoint(x: self.size.width/2, y: self.size.height*CGFloat(i))
        background.zPosition = 0
        background.name = "Background"
        self.addChild(background)
            
        }
        
        player.setScale(1)
        // the player started 20% from the up the screen, y: is to be in the button of the screen
        player.position = CGPoint(x: self.size.width/2, y: 0 - player.size.height)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(player)
        
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width*0.15, y: self.size.height + scoreLabel.frame.height)
        scoreLabel.zPosition = 100 // label will be safely always be on top of everything
        self.addChild(scoreLabel)
        
        liveLabel.text = "Lives: 3"
        liveLabel.fontSize = 70
        liveLabel.fontColor = SKColor.white
        liveLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        liveLabel.position = CGPoint(x: self.size.width*0.85, y: self.size.height + liveLabel.frame.height)
        liveLabel.zPosition = 100
        self.addChild(liveLabel)
        
        // this is an Action to only affects the
        // y coordinate so to make the label just moving down
        let moveOnScreen = SKAction.moveTo(y: self.size.height*0.9, duration: 0.3)
        scoreLabel.run(moveOnScreen)
        liveLabel.run(moveOnScreen)
        
        tapToStartLabel.text = "Tap To Begin"
        tapToStartLabel.fontSize = 100
        tapToStartLabel.fontColor = SKColor.white
        tapToStartLabel.zPosition = 1
        tapToStartLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        tapToStartLabel.alpha = 0 // 1 is normal, 0 is completely seepho , 0.5 is half see "hidden"
        self.addChild(tapToStartLabel)
        
        
        let fadeInAction = SKAction.fadeIn(withDuration: 0.3)
        tapToStartLabel.run(fadeInAction)
//        startNewLevel()

    }
    
    // to store the time of the last frame,
    // to compare that with how much time is passed
    var lastUpdateTime: TimeInterval = 0
    var deltaFrameTime: TimeInterval = 0
    // the amount of the movement per second
    var amountToMovePerSecond: CGFloat = 600.0
    
    
    // will start at everyGame loop
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }else{
            deltaFrameTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
        }
        // store how much we have to move each of our backgrounds
        let amountToMoveBackground = amountToMovePerSecond * CGFloat(deltaFrameTime)
        
        self.enumerateChildNodes(withName: "Background"){
            background, stop in
            if self.currentGameState == gameState.inGame{
            // how much we have to move our Background by
            background.position.y -= amountToMoveBackground
            }
            
            // background.position.y the ancher
            // if the first backgrounf less than second then move it
            if background.position.y < -self.size.height{
                background.position.y += self.size.height*2
            }
        }
    }
    
    func startGame(){
        // the game status will change from pre to in
        currentGameState = gameState.inGame
        // the label will go after tapping on the screen
        let fadeOutAction = SKAction.fadeOut(withDuration: 1)
        let deleteAction = SKAction.removeFromParent()
        let deleteSequence = SKAction.sequence([fadeOutAction, deleteAction])
        tapToStartLabel.run(deleteSequence)
        
        // Ship should move on the bar this means only y axis is affected
        let moveShipOntoScreenAction = SKAction.moveTo(y: self.size.height*0.2, duration: 0.5)
        let startLevel = SKAction.run(startNewLevel)
        let startGameSequence = SKAction.sequence([moveShipOntoScreenAction, startLevel])
        player.run(startGameSequence)
        
    }


    func startNewLevel(){
        
        levelNumber += 1
        
        if self.action(forKey: "spawningEnemies") != nil{
            self.removeAction(forKey: "spawningEnemies")
        }
        
        var levelDuration = TimeInterval()
        
        switch levelNumber {
        case 1: levelDuration = 1.2
        case 2: levelDuration = 1
        case 3: levelDuration = 0.8
        case 4: levelDuration = 0.5
        default:
            levelDuration = 0.5
            print("can't find level info")
        }
        
        
        let spawn = SKAction.run(spwanEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey: "spawningEnemies")
        
    }
    
    func addScore(){
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)"
        
        if gameScore == 5 || gameScore == 15 || gameScore == 35 {
            startNewLevel()
        }
        
      
        
    }
    
    
    func loseAlife() {
        liveNumber -= 1
        liveLabel.text = "Lives: \(liveNumber)"
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        liveLabel.run(scaleSequence)
        
        if liveNumber < 1{
            runGameOver()
        }
        
    }
    
    func runGameOver() {
        
        currentGameState = gameState.afterGame
        
        self.removeAllActions()
        
        // this generate us a list of all objects with the reference name Bullet
        self.enumerateChildNodes(withName: "Bullet"){ // to loop round every Objects in this list
            bullet, stop in
            
            bullet.removeAllActions()
        }
        
        self.enumerateChildNodes(withName: "Enemy"){
            enmey, stop in
            
            enmey.removeAllActions()
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene = SKAction.wait(forDuration: 1)
        let changeSceneSquence = SKAction.sequence([waitToChangeScene, changeSceneAction])
        self.run(changeSceneSquence)
        
    }
    
    func changeScene(){

        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode
        let myTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: myTransition)
        
        
    }
    
    func fireBullet(){
        
        // it must be only locally not globally,
        // because everytime we fire a Bullet it will be load
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.name = "Bullet"
        bullet.setScale(1)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound,moveBullet, deleteBullet])
        bullet.run(bulletSequence)
        
    }
    

    func spwanEnemy()  {
        let radomXStart = random(min: gameArea.minX, max: gameArea.maxX)
        let randomXEnd  = random(min: gameArea.minX, max: gameArea.maxX)
        
        let startPoint = CGPoint(x: radomXStart, y: self.size.height * 1.2)
        let endPoint   = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)

        let enemy = SKSpriteNode(imageNamed: "enemyShip")
        enemy.name = "Enemy"
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        // take the physicsbody of the enemy and put it in the PhysicsCategories.Enemy
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        // we don't need the enemy phsicsbody to collise with anything
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        // ther are  or hits only with physicsabody of bullet or player
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.player | PhysicsCategories.Bullet
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.5)
        let deleteEnemy = SKAction.removeFromParent()
        let loseAlifeAction = SKAction.run(loseAlife)
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, loseAlifeAction])
        
        if currentGameState == gameState.inGame {
            enemy.run(enemySequence)
        }
        
        
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy, dx)
        enemy.zRotation = amountToRotate
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // bullet
        var body1 = SKPhysicsBody()
        // enemy
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            
            body1 = contact.bodyA
            body2 = contact.bodyB
            
        }else{
            
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.player && body2.categoryBitMask == PhysicsCategories.Enemy {
            
            if body1.node != nil {
                spawnExplosion(spawnPositon: body1.node!.position)
            }
            
            if body2.node != nil {
                spawnExplosion(spawnPositon: body2.node!.position)
            }

            
            // if the player has hit the enemy
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            runGameOver()

        }
        
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy
              /* the bullet can hit the enemy if the enemy in the screen not outside */ {
            
            addScore()
            
            if body2.node != nil {
                if (body2.node?.position.y)! > self.size.height {
                    return
                }
            }
            
            if body2.node != nil {
                spawnExplosion(spawnPositon: body2.node!.position)
            }
            
            
            // if the bullet has hit the enemy
            // if 2 bullets has hit the Ship in the same second then the app will crash
            // that why there is ? sign
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
        
        
        
    }
    
    func spawnExplosion(spawnPositon: CGPoint){
        
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = spawnPositon // starting position
        explosion.zPosition = 3 // on the top of the ship
        explosion.setScale(0)
        self.addChild(explosion)
                
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        
        let explosionSequence = SKAction.sequence([explosionSound,scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentGameState == gameState.PreGame {
            startGame()
        }
        
        else if currentGameState == gameState.inGame {
            fireBullet()
        }
//        spwanEnemy()
//        didBeginContact(contact: self.player)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            if currentGameState == gameState.inGame {
                player.position.x += amountDragged
            }
            
            if player.position.x > gameArea.maxX { //- player.size.width/2 {
                player.position.x = gameArea.maxX  //- player.size.width/2
            }
            
            if player.position.x < gameArea.minX {//+ player.size.width/2  {
//            if player.position.x < CGRectEdge(gameArea){
                player.position.x = gameArea.minX  //+ player.size.width/2
            }
            
         }
            
    }
    

    
    
    
    }

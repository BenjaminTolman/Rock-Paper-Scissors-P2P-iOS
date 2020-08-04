//
//  ViewController.swift
//  RockPaperScissors
//
//  Created by Benjamin Tolman on 6/19/20.
//  Copyright © 2020 Benjamin Tolman. All rights reserved.
//

//Rock Paper Scissors Peer to peer game example by Benjamin Tolman.

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate{
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var paperButton: UIButton!
    @IBOutlet weak var rockButton: UIButton!
    @IBOutlet weak var scissorsButton: UIButton!
    
    @IBOutlet weak var playerTwoImage: UIImageView!
    @IBOutlet weak var playerOneImage: UIImageView!
    
    //Connecton variables.
    var peerID: MCPeerID! //The devices name as viewed by other browsing devices.
    var session: MCSession! //connection between devices
    var browser: MCBrowserViewController! //this is a prebuild view controllet that searches for nearby adverttiseers
    var advertiser: MCNearbyServiceAdvertiser! //Easily advertise ourselves to nearby MCBrowsers.
    
    let serviceID = "rpc" //Channel
    
    var endMessage = ""
    
    //Score labels.
    @IBOutlet weak var winsLabel: UILabel!
    var winsValue = 0
    @IBOutlet weak var loseLabel: UILabel!
    var loseValue = 0
    @IBOutlet weak var drawLabel: UILabel!
    var drawValue = 0
    
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var statusText: UILabel!
    
    //Timer.
    var timer = Timer() //Times intervals.
    var countDown = 1
    
    //Replay timer.
    var replayTimer = Timer() //Times intervals.
    var replayTime = 3
    
    //This checks for if the game is on (Players can select a move)
    var gameOn = false;
    
    //Variables to track player's status.
    var playerOneSelection = 0;
    var playerTwoSelection = 0;
    var playerOneDone = false;
    var playerTwoDone = false;
    
    //Play button tapped
    var playerOneReadyToPlay = false
    var playerTwoReadyToPlay = false
    
    var isConnected = false
    
    var buttonsOn = true
    
    @IBOutlet weak var playerTwoBG: UIView!
    @IBOutlet weak var playerOneBG: UIView!
    
    //This covers the game screen and has the play / Connect buttons on it.
    @IBOutlet weak var gameCover: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Do any additional setup after loading the view.
        
        //Fix button aspects.
        paperButton.imageView!.contentMode = UIView.ContentMode.scaleAspectFit
        rockButton.imageView!.contentMode = UIView.ContentMode.scaleAspectFit
        scissorsButton.imageView!.contentMode = UIView.ContentMode.scaleAspectFit
        
        //Setup MC
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        //Use peer id to setup session.
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        
        session.delegate = self
        
        //Setup and start advertising now
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceID)
        
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        //Set score labels to default.
        winsLabel.text = "Win: 0"
        loseLabel.text = "Lose: 0"
        drawLabel.text = "Draw: 0"
        
        connectButton.titleLabel?.minimumScaleFactor = 0.25
        playButton.titleLabel?.minimumScaleFactor = 0.25
        
        connectButton.isHidden = false
        connectButton.isEnabled = true
        
        playButton.isHidden = true
        playButton.isEnabled = false
        
        //Set move buttons to false.
        showButtons()
        
        navItem.title = "Rock Paper Scissors"
        statusText.text = "Connect to Play."
        
        playerTwoImage.image = #imageLiteral(resourceName: "Waiting")
        playerOneImage.image = #imageLiteral(resourceName: "Waiting")
        
    }
    
    
    //Button select.
    @IBAction func moveSelected(_ sender: UIButton) {
        
        //If it is time to pick a move.
        
        if(self.gameOn)
        {
            var selection = ""
            playerOneDone = true
            switch sender.tag {
            case 0:
                selection = "rock"
                self.playerOneSelection = 0;
                self.playerOneImage.image =  #imageLiteral(resourceName: "Rock")
            case 1:
                selection = "paper"
                self.playerOneSelection = 1;
                self.playerOneImage.image =  #imageLiteral(resourceName: "Paper")
            case 2:
                selection = "scissors"
                self.playerOneSelection = 2;
                self.playerOneImage.image =  #imageLiteral(resourceName: "Scissors")
                
            default:
                print("error")
            }
            
            if let encodedString = selection.data(using: .utf8){
                
                do
                {
                    try session.send(encodedString, toPeers: session.connectedPeers, with: .reliable)
                }
                    
                catch
                {
                    print("error")
                    return
                }
            }
        }
    }
    
    //Move received.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if let messageText:String = String(data: data, encoding: String.Encoding.utf8){
            
            DispatchQueue.main.async {
                // Run UI Updates
                
                //Register selections if gameOn.
                if(self.gameOn)
                {
                    if messageText == "rock"
                    {
                        self.playerTwoSelection = 0;
                    }
                    if messageText == "paper"
                    {
                        self.playerTwoSelection = 1;
                    }
                    if messageText == "scissors"
                    {
                        self.playerTwoSelection = 2;
                    }
                    
                    self.playerTwoDone = true
                }
                
                if messageText == "play"{
                    
                    self.playerTwoReadyToPlay = true
                    self.statusText.text = "Opponent Ready"
                    
                    if self.playerOneReadyToPlay{
                        
                        self.startGame()
                    }
                }
            }
        }
    }
    
    func startGame()
    {
        gameCover.isHidden = true
        gameOn = true
        
        self.statusText.text = "Rock, Paper or Scissors!"
        
        showButtons()
        
        //Start timer.
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.increment), userInfo: nil, repeats: true)
          
    }
    
    //Incrementing the timer.
    @objc func increment()
    {
        if countDown <= 3
        {
            statusText.text = countDown.description
            countDown += 1
        }
        else
        {
            statusText.text = "SHOOT!"
            countDown = 1
            
            //Stop timer.
            self.timer.invalidate()
            gameOn = false
            endGame()
        }
    }
    
    func endGame()
    {
        if playerTwoDone
        {
            if playerTwoSelection == 0{self.playerTwoImage.image =  #imageLiteral(resourceName: "Rock")}
            if playerTwoSelection == 1{self.playerTwoImage.image =  #imageLiteral(resourceName: "Paper")}
            if playerTwoSelection == 2{self.playerTwoImage.image =  #imageLiteral(resourceName: "Scissors")}
        }
        
        let winner = scoreCalculation()
        
        if winner == 0
        {
            drawValue += 1
            drawLabel.text = "Draw: \(drawValue.description)"
            statusText.text = "Draw"
            endMessage = "had a Draw"
            
            playerOneBG.backgroundColor = UIColor.systemGray
            playerTwoBG.backgroundColor = UIColor.systemGray
            
        }
        
        if winner == 1
        {
            winsValue += 1
            winsLabel.text = "Win: \(winsValue.description)"
            statusText.text = "You Won"
            endMessage = "Won"
            
            playerOneBG.backgroundColor = UIColor.systemGreen
            playerTwoBG.backgroundColor = UIColor.systemRed
        }
        
        if winner == 2
        {
            loseValue += 1
            loseLabel.text = "Lose: \(loseValue.description)"
            statusText.text = "You Lose"
            endMessage = "Lost"
            
            playerOneBG.backgroundColor = UIColor.systemRed
            playerTwoBG.backgroundColor = UIColor.systemGreen
        }
        
        //Start replay timer.
        self.replayTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.incrementReplay), userInfo: nil, repeats: true)
    }
    
    //Incrementing the timer.
    @objc func incrementReplay()
    {
        if replayTime < 0
        {
            replayTime -= 1
        }
        else
        {
            self.replayTimer.invalidate()
            //Show alert for resetting game.
            
            playerOneReadyToPlay = false
            playerTwoReadyToPlay = false
            
            //Create the alert controller.
            let alertController = UIAlertController(title: "Continue", message: "Round complete! You \(endMessage).", preferredStyle: .alert)
            
            //Create the actions.
            let resetAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.resetGame()
            }
            //Add the action.
            alertController.addAction(resetAction)
            
            //Present the controller.
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func scoreCalculation() -> Int
    {
        //wld by player 1.
        var wld = 0 //0: Draw, 1: Win, 2: lose.
        
        if playerOneSelection == 0{
            if playerTwoSelection == 0{  wld = 0 }//Draw
            if playerTwoSelection == 1{  wld = 2 }//PlayerTwo wins
            if playerTwoSelection == 2{  wld = 1 }//PlayerTwo loses
        }
        if playerOneSelection == 1{
            if playerTwoSelection == 0{  wld = 1  }//PlayerTwo loses
            if playerTwoSelection == 1{  wld = 0  }//Draw
            if playerTwoSelection == 2{  wld = 2  }//PlayerTwo wins
        }
        if playerOneSelection == 2{
            if playerTwoSelection == 0{  wld = 2 }//PlayerTwo wins
            if playerTwoSelection == 1{  wld = 1 }//PlayerTwo loses
            if playerTwoSelection == 2{  wld = 0 }//Draw
        }
        
        if !playerTwoDone && !playerOneDone { wld = 0}
        if playerTwoDone && !playerOneDone { wld = 2}
        if !playerTwoDone && playerOneDone { wld = 1}
        
        return wld
    }
    
    func resetGame(){
        
        gameCover.isHidden = false
        
        playButton.isHidden = false
        playButton.isEnabled = true
        
        playerTwoDone = false
        playerOneDone = false
        
        //Set move buttons to false.
        showButtons()
        
        //If player is already ready then dont overwrite it.
        if statusText.text != "Opponent Ready"
        {
            statusText.text = "Rock Paper Scissors"
        }
        
        playerTwoImage.image = #imageLiteral(resourceName: "Waiting")
        playerOneImage.image = #imageLiteral(resourceName: "Waiting")
        
        playerOneBG.backgroundColor = UIColor.systemTeal
        playerTwoBG.backgroundColor = UIColor.systemTeal
    }
    
    
    func showButtons()
    {
        if buttonsOn
        {
            rockButton.isHidden = true
            rockButton.isEnabled = false
            
            paperButton.isHidden = true
            paperButton.isEnabled = false
            
            scissorsButton.isHidden = true
            scissorsButton.isEnabled = false
            
            buttonsOn = false
        }
        else if !buttonsOn
        {
            rockButton.isHidden = false
            rockButton.isEnabled = true
            
            paperButton.isHidden = false
            paperButton.isEnabled = true
            
            scissorsButton.isHidden = false
            scissorsButton.isEnabled = true
            
            buttonsOn = true
        }
    }
   
    
    //Incoming invitation request.  Call the invitationHandler block and a valid session to connect the inviting peer to the session.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        let alert = UIAlertController(title: "Incoming game request from \(peerID.displayName)", message: "Do you want to accept this game?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (action) in
            
            //accept connection.
            invitationHandler(true, self.session)
            
        }))
        alert.addAction(UIAlertAction(title: "Decline", style: .default, handler: { (action) in
            
            //accept connection.
            invitationHandler(false, self.session)
            
        }))
        
        self.present(alert, animated: true)
    }
    
    
    //Remote peer changed state.
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState){
        
        //Update status on the nav bar.
        DispatchQueue.main.async {
            
            if state == MCSessionState.connected{
                self.navItem.title = "connected"
                self.statusText.text = "Waiting for Game."
                self.isConnected = true
                
                self.connectButton.isHidden = true
                self.connectButton.isEnabled = false
                
                self.playButton.isHidden = false
                self.playButton.isEnabled = true
                
            }
            else
            {
                self.navItem.title = "disconnected"
                self.statusText.text = "Connect to Play."
                
                self.connectButton.isHidden = false
                self.connectButton.isEnabled = true
                
                self.playButton.isHidden = true
                self.playButton.isEnabled = false
                
                self.isConnected = false
            }
        }
    }
    
    @IBAction func playButton(_ sender: Any) {
        
        if isConnected
        {
            playerOneReadyToPlay = true
            
            let playString = "play"
            if let encodedString = playString.data(using: .utf8){
                
                do
                {
                    try session.send(encodedString, toPeers: session.connectedPeers, with: .reliable)
                }
                catch
                {
                    print("error")
                }
                
                if playerTwoReadyToPlay
                {
                    self.startGame()
                    print("started at pressed Play")
                }
                    
                else
                {
                    self.statusText.text = "Waiting for Opponent"
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    @IBAction func connectButton(_ sender: Any) {
        
        
        //Browser will look for advertisers that share the same service id.
        browser = MCBrowserViewController(serviceType: serviceID, session: session)
        
        browser.delegate = self
        self.present(browser, animated: true, completion: nil)
    }
    
    
    //If selection was made then dismiss the view.
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    //If cancel button tapped dismiss the view.
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        browserViewController.dismiss(animated: true, completion: nil)
    }
}




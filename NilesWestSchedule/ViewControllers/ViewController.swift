//
//  ViewController.swift
//  NilesWestSchedule
//
//  Created by Michael Filippini on 8/19/19.
//  Copyright © 2019 Michael Filippini. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UIKit.UIGestureRecognizerSubclass

var todaysDate = ""

var dailySchedule: [[Any]] = []
var usersSchedule: [[Any]] = []
var dailyScheduleTemp: [[Any]] = []
var usersScheduleTemp: [[Any]] = []
var upcomingSpecialDays: [[Any]] = []
var upcomingSpecialDaysTemp: [[Any]] = []
var unNeededClasses: [String] = []
var scheduleName = ""
var specialMessage = ""
var buttonDirection: Bool?
var collapsingButtonArray: [UIButton] = []
var selectedButton: Int = 0

    /*
        Schedules----------
            - daily has all classes
            - users has only classes that pertain to users
 
            Period = [PeriodName, stringStartTime, stringEndTime, 24hrStartTime, 24hrEndTime] filled after loadSchedule is completed
            Filled durring loadSchedule()
            string times are like 8:00
            real times are 15.40
 
        Special Days----------
            date= ["5/5","Late Start",1709]
            is sorted and dates before today are removed
 
    */

enum State {
    case closed
    case open
}

var currentState: State = .closed

extension State {
    var opposite: State {
        switch self {
        case .open: return .closed
        case .closed: return .open
        }
    }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    
    
    var ref: DatabaseReference!
    var update: DispatchWorkItem?
    var timeTillNextUpdate: Double?
    var timeTillNextClass: Double?
    var iconsList: [UIImage] = []
    var currentPeriodIndex: Int?
    var tillEndOfCurrentBool = true
    
    weak var insideView: UIView!
    var headerView: UIView?
    var titleHeader: HeaderView?
    private var countdownHeader: HeaderView?
    private let popupOffset: CGFloat = UIScreen.main.bounds.size.height - 150
    
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    @IBOutlet weak var masterButton: UIButton!
    
    @IBOutlet weak var drawerView: UIView!
    @IBOutlet weak var drawerHeightConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
        
        scheduleCollectionView.isUserInteractionEnabled = true
        scheduleCollectionView.isScrollEnabled = true
        scheduleCollectionView.bounces = false
        drawerView.addGestureRecognizer(panRecognizer)
        drawerView.layer.cornerRadius = 25
        drawerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panRecognizer.delegate = self
        
        //color
        drawerView.layer.backgroundColor = UIColor.background.cgColor
        self.view.backgroundColor = .white
        
        //change date
        let formater = DateFormatter()
        formater.dateFormat = "EEEE, M/d"
        //dateLabel.text = formater.string(from: Date())

        addIcons()
        buttonSetup()
        addButtonsToArray()
        
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .darkContent
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let gesture = (gestureRecognizer as! UIPanGestureRecognizer)
        let direction = gesture.velocity(in: drawerView).y
        
        if ((currentState == .open && scheduleCollectionView.contentOffset.y == 0 && direction > 0) || currentState == .closed) {
            scheduleCollectionView.isScrollEnabled = false
        } else {
            scheduleCollectionView.isScrollEnabled = true
        }

        return false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        scheduleCollectionView.register(UINib.init(nibName: "UpcomingDaysCell", bundle: nil), forCellWithReuseIdentifier: "UpcomingDaysCell")
        loadSchedule()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupCollectionViewHeader()
    }
    
    //MARK: Header
    func setupCollectionViewHeader(){
        let screenSize = UIScreen.main.bounds.size
        scheduleCollectionView.backgroundColor = .clear
        
        headerView = UIView()
        titleHeader = HeaderView() as! HeaderView
        countdownHeader = HeaderView() as! HeaderView
                
        headerView?.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height - 150)
        headerView?.clipsToBounds = true
        headerView?.backgroundColor = .white
        
        let countdownConst: CGFloat = 0.77
        let countdownsize = screenSize.width * countdownConst
        let countdownX = (screenSize.width/2) - (countdownsize/2)
        let countdownY = (screenSize.height/2) - (countdownsize/2)
        
        let labelConstY: CGFloat = 0.4
        let labelConstX: CGFloat = 0.9
        
        let labelViewHeight = countdownY * labelConstY
        let labelViewWidth = screenSize.width * labelConstX
        
        let labelX = (screenSize.width/2) - (labelViewWidth/2)
        let labelY = (countdownY/2) - (labelViewHeight/2)
        
        countdownHeader?.layer.backgroundColor = UIColor.blue.cgColor
        titleHeader?.layer.backgroundColor = UIColor.red.cgColor
    
        titleHeader?.frame = CGRect(x: labelX, y: labelY, width: labelViewWidth, height: labelViewHeight)
        countdownHeader?.frame = rectForCountdown(screenSize.height - 200, 150, screenSize.height - 200)

        
        headerView?.addSubview(titleHeader!)
        headerView?.addSubview(countdownHeader!)
        view.addSubview(headerView!)
        
        /*
        let insideView = UIView(frame: .zero)
        insideView.translatesAutoresizingMaskIntoConstraints = false
        self.countdownHeader!.addSubview(insideView)
        NSLayoutConstraint.activate([
            insideView.topAnchor.constraint(equalTo: self.countdownHeader!.topAnchor, constant: 32),
            insideView.leadingAnchor.constraint(equalTo: self.countdownHeader!.leadingAnchor, constant: 32),
            insideView.trailingAnchor.constraint(equalTo: self.countdownHeader!.trailingAnchor, constant: -32),
            insideView.bottomAnchor.constraint(equalTo: self.countdownHeader!.bottomAnchor, constant: -32)
        ])
        self.insideView = insideView
        
        insideView.backgroundColor = .clear
 */
        setupViewsInHeader()

        
    }
    
    func makeCircle(){
        let backgroundCircle = CAShapeLayer()
        let outsideRing = CAShapeLayer()
        
        // outside ring only appears in the animation as the progress bar
        /*
        outsideRing.path = UIBezierPath(arcCenter: countdownHeader!.center, radius: (countdownHeader!.frame.width - 20)/2, startAngle: CGFloat(0), endAngle: CGFloat(2*Float.pi), clockwise: true).cgPath
        
        outsideRing.fillColor = UIColor.accent.cgColor
        outsideRing.lineWidth = 8
        outsideRing.strokeEnd = 0
        outsideRing.zPosition = -50
        outsideRing.lineCap = CAShapeLayerLineCap.round
        */
        // background circle is similar to the ring but it has a fill color and displays a "track in grey"
        backgroundCircle.path = UIBezierPath(arcCenter: countdownHeader!.center, radius: (countdownHeader!.frame.width - 20)/2, startAngle: CGFloat(Float.pi/2.0), endAngle: CGFloat(Float.pi*2.5), clockwise: false).cgPath
        
        backgroundCircle.strokeColor = UIColor.background.cgColor
        backgroundCircle.fillColor = UIColor.accent.cgColor
        backgroundCircle.lineWidth = 8
        backgroundCircle.zPosition = -60 // behind the ring
        backgroundCircle.strokeEnd = 1
        
        //ringAnimate(ring: outsideRing, indexOfCell: indexOfCell, section: section)
    }
    
   /* func ringAnimate(ring: CAShapeLayer, indexOfCell: Int, section: Int){
        let progressBarAnimate = CABasicAnimation(keyPath: "strokeEnd")
        let progressPercent = Float32(timesCompleteArray[section][indexOfCell]) / Float32(timesPerDayArray[section][indexOfCell])
        
        progressBarAnimate.toValue = CGFloat(progressPercent)
        progressBarAnimate.duration = 0.7
        ring.strokeColor = colors[colorsArray[section][indexOfCell]]![palatteIdentifier].cgColor
        progressBarAnimate.isRemovedOnCompletion = false
        progressBarAnimate.fillMode = CAMediaTimingFillMode.forwards
        
        ring.add(progressBarAnimate,forKey: nil)
    }
    */
    
    func setupViewsInHeader(){
        //header 1 is top banner
        titleHeader?.layer.cornerRadius = 25
        
        let gradient2 = CAGradientLayer()
        gradient2.frame = CGRect(x: 0, y: 0, width: 100, height: 100)

        gradient2.colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
        
        let gradient1 = CAGradientLayer()
              gradient1.frame = self.titleHeader!.bounds
              gradient1.colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
        
        //insideView!.layer.addSublayer(gradient2)
        titleHeader?.layer.addSublayer(gradient1)
                
        //header 2 is middle display
       // countdownHeader?.layer.backgroundColor = UIColor.main.cgColor
        /*
        let backgroundCircle = CAShapeLayer()
        let outsideRing = CAShapeLayer()
        
        let center = CGPoint(x: countdownHeader!.frame.width/2, y: countdownHeader!.frame.height/2)
        
        // outside ring only appears in the animation as the progress bar
        outsideRing.path = UIBezierPath(arcCenter: center , radius: (countdownHeader!.frame.width - 20)/2, startAngle: CGFloat(0), endAngle: CGFloat(1*Float.pi), clockwise: true).cgPath
        
        outsideRing.fillColor = UIColor.accent.cgColor
        outsideRing.lineWidth = 8
        outsideRing.strokeEnd = 10
        outsideRing.zPosition = -50
        outsideRing.lineCap = CAShapeLayerLineCap.round
        
        // background circle is similar to the ring but it has a fill color and displays a "track in grey"
        backgroundCircle.path = UIBezierPath(arcCenter: center, radius: (countdownHeader!.frame.width - 20)/2, startAngle: CGFloat(Float.pi/2.0), endAngle: CGFloat(Float.pi*2.5), clockwise: false).cgPath
        
        backgroundCircle.strokeColor = UIColor.background.cgColor
        backgroundCircle.fillColor = UIColor.accent.cgColor
        backgroundCircle.lineWidth = 8
        backgroundCircle.zPosition = -60 // behind the ring
        backgroundCircle.strokeEnd = 1
        
        countdownHeader?.layer.addSublayer(backgroundCircle)
        countdownHeader?.layer.addSublayer(outsideRing)
*/
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let screenSize = UIScreen.main.bounds.size

        let maxHeight = screenSize.height - 200
        let minHeight: CGFloat = 150
        
        let y = (screenSize.height - drawerHeightConstraint.constant)
        let height = max(y, minHeight)
        
        
        headerView?.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: height)
        
        //countdownHeader?.transform = CGAffineTransform(translationX: 1, y: 1)
        //countdownHeader?.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        //translateCountdown(height, minHeight, maxHeight,countdownHeader!.frame)
        
        countdownHeader?.frame = rectForCountdown(height, minHeight, maxHeight)
        //rerenderSubview2()
        print("viewScrolled")
        titleHeader?.frame = rectForLabel(height, minHeight, maxHeight, rectForCountdown(minHeight, minHeight, maxHeight))
        
        titleHeader?.layer.sublayers![0].frame = CGRect(x: 0, y: 0, width: titleHeader!.frame.width, height: titleHeader!.frame.height)
        
    }
    
    func rectForLabel(_ height: CGFloat, _ minHeight: CGFloat, _ maxHeight: CGFloat, _ otherView: CGRect) -> CGRect{
        let screenSize = UIScreen.main.bounds.size

        //editables
        let labelConstY: CGFloat = 0.4
        let labelConstX: CGFloat = 0.9
        let labelFinalCosntX: CGFloat = 0.9
        let countdownConst: CGFloat = 0.77
        
        //final
        let finalSizeX: CGFloat = otherView.minX - 25 * labelFinalCosntX
        let finalSizeY: CGFloat = otherView.height
        
        let finalX: CGFloat = (otherView.minX - finalSizeX) / 2
        let finalY: CGFloat = otherView.minY
         
        
        //initial
        let countdownsize = screenSize.width * countdownConst
        let countdownY = (screenSize.height/2) - (countdownsize/2)
        
        let labelViewHeight = countdownY * labelConstY
        let labelViewWidth = screenSize.width * labelConstX
        let labelX = (screenSize.width/2) - (labelViewWidth/2)
        let labelY = (countdownY/2) - (labelViewHeight/2)
         
         
         let labelSizeXEQ = ((labelViewWidth - finalSizeX)/(maxHeight - minHeight)) * (height - maxHeight) + labelViewWidth
         let labelSizeYEQ = ((labelViewHeight - finalSizeY)/(maxHeight - minHeight)) * (height - maxHeight) + labelViewHeight
        
         var labelXEQ: CGFloat = 0
         var labelYEQ: CGFloat = 0
        
         
         if(height <= maxHeight){
            labelXEQ = ((labelX - finalX)/(maxHeight - minHeight)) * (height - maxHeight) + labelX
            labelYEQ = ((labelY - finalY)/(maxHeight - minHeight)) * (height - maxHeight) + labelY
         }else{
            labelXEQ = (screenSize.width/2) - (labelSizeXEQ/2)
            labelYEQ = (countdownY/2) - (labelSizeYEQ/2)
         }
        
         return CGRect(x: labelXEQ, y: labelYEQ, width: labelSizeXEQ, height: labelSizeYEQ)
    }
    
    func translateCountdown(_ height: CGFloat, _ minHeight: CGFloat, _ maxHeight: CGFloat, _ current: CGRect) {
        let screenSize = UIScreen.main.bounds.size
        
        //editables
        let countdownConst: CGFloat = 0.77
        let finalSizeConst: CGFloat = 0.8
        
        //final
        let finalSize: CGFloat = (minHeight - view.safeAreaInsets.top) * finalSizeConst
        let finalX: CGFloat = screenSize.width - finalSize - 25
        let finalY: CGFloat = (minHeight + view.safeAreaInsets.top)/2 - finalSize/2
        
        //initial
        let countdownsize = screenSize.width * countdownConst
        let countdownX = (screenSize.width/2) - (countdownsize/2)
        let countdownY = (screenSize.height/2) - (countdownsize/2)
        
        let countdownSizeEQ = ((countdownsize - finalSize)/(maxHeight - minHeight)) * (height - maxHeight) + countdownsize
        
        var countdownXEQ: CGFloat = 0
        var countdownYEQ: CGFloat = 0

        if(height <= maxHeight){
            countdownXEQ = ((countdownX - finalX)/(maxHeight - minHeight)) * (height - maxHeight) + countdownX
            countdownYEQ = ((countdownY - finalY)/(maxHeight - minHeight)) * (height - maxHeight) + countdownY
        }else{
            print("height > max")
            countdownXEQ = (screenSize.width/2) - (countdownSizeEQ/2)
            countdownYEQ = (screenSize.height/2) - (countdownSizeEQ/2)
        }
        
        //countdownHeader?.transform = CGAffineTransform(translationX: countdownXEQ-current.minX, y: countdownYEQ-current.minY)
        countdownHeader?.transform = CGAffineTransform(translationX: 10, y: -10)
        countdownHeader?.transform = CGAffineTransform(scaleX: finalSize/countdownsize, y: finalSize/countdownsize)
        
        
    }
    
    func rectForCountdown(_ height: CGFloat, _ minHeight: CGFloat, _ maxHeight: CGFloat) -> CGRect{
        let screenSize = UIScreen.main.bounds.size

        //editables
        let countdownConst: CGFloat = 0.77
        let finalSizeConst: CGFloat = 0.8
        
        //final
        let finalSize: CGFloat = (minHeight - view.safeAreaInsets.top) * finalSizeConst
        let finalX: CGFloat = screenSize.width - finalSize - 25
        let finalY: CGFloat = (minHeight + view.safeAreaInsets.top)/2 - finalSize/2
        
        //initial
        let countdownsize = screenSize.width * countdownConst
        let countdownX = (screenSize.width/2) - (countdownsize/2)
        let countdownY = (screenSize.height/2) - (countdownsize/2)
        
        
        let countdownSizeEQ = ((countdownsize - finalSize)/(maxHeight - minHeight)) * (height - maxHeight) + countdownsize
       
        var countdownXEQ: CGFloat = 0
        var countdownYEQ: CGFloat = 0

        if(height <= maxHeight){
           countdownXEQ = ((countdownX - finalX)/(maxHeight - minHeight)) * (height - maxHeight) + countdownX
           countdownYEQ = ((countdownY - finalY)/(maxHeight - minHeight)) * (height - maxHeight) + countdownY
        }else{
            print("height > max")
            countdownXEQ = (screenSize.width/2) - (countdownSizeEQ/2)
            countdownYEQ = (screenSize.height/2) - (countdownSizeEQ/2)
        }
        
        return CGRect(x: countdownXEQ, y: countdownYEQ, width: countdownSizeEQ, height: countdownSizeEQ)
    }
    
    // MARK: Buttons

    func addIcons(){
        if #available(iOS 13.0, *) {
            
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .large)
            
            let cal = UIImage(systemName: "calendar", withConfiguration: config)!
            let gear = UIImage(systemName: "gear", withConfiguration: config)!
            let bell = UIImage(systemName: "bell", withConfiguration: config)!
            
            self.iconsList = [cal,gear,bell]
        } else {
            // Fallback on earlier versions
        }
        print("icons:\(iconsList)")
    }
    
    
    func buttonSetup(){
        masterButton.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.84, alpha: 1)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .large)

        masterButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        masterButton.layer.cornerRadius = 27
        buttonDirection = true
        masterButton.addTarget(self, action: #selector(expandButton), for: .touchUpInside)
        masterButton.addTarget(self, action: #selector(holdDownMaster), for: .touchDown)
        masterButton.addTarget(self, action: #selector(cancelHoldMaster), for: .touchDragExit)
        
    }
    
    func addButtonsToArray(){
        let start = masterButton.frame
        let color = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.84, alpha: 1)
        
        let movingViewZero = UIButton(frame: start)
        collapsingButtonArray.append(movingViewZero)
        movingViewZero.tag = 0
        
        let movingViewOne = UIButton(frame: start)
        collapsingButtonArray.append(movingViewOne)
        movingViewOne.tag = 1
        
        let movingViewTwo = UIButton(frame: start)
        collapsingButtonArray.append(movingViewTwo)
        movingViewTwo.tag = 2
        
        for button in collapsingButtonArray{
            button.backgroundColor = color
            button.tintColor = .black
            button.setImage(iconsList[button.tag], for: .normal)
            button.layer.cornerRadius = 25
            button.addTarget(self, action: #selector(subButton), for: .touchUpInside)
            button.addTarget(self, action: #selector(holdDownSub), for: .touchDown)
            button.addTarget(self, action: #selector(cancelHoldSub), for: .touchDragExit)

        }
    }

    @objc func holdDownMaster(sender: UIButton){
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)

        UIView.animate(withDuration: 0.02,
            animations: {
                sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                sender.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.7, alpha: 1)
            }, completion: nil)
    }
    
    
    @objc func holdDownSub(sender: UIButton){
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)

        UIView.animate(withDuration: 0.05,
            animations: {
                sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                sender.backgroundColor = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.7, alpha: 1)
        }, completion: nil)
    }
    
    @objc func subButton(sender: UIButton){
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.9)

        print(sender.tag)
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.84, alpha: 1)
        }
        
        
        //[cal,gear,bell]
        if(sender.tag == 0){
            performSegue(withIdentifier: "toUpcomingSegue", sender: nil)
        }
        else if(sender.tag == 1){
            performSegue(withIdentifier: "toSettingsSegue", sender: nil)

        }else{
            performSegue(withIdentifier: "toNotificationsSegue", sender: nil)
        }
        
    }

    @objc func cancelHoldSub(sender: UIButton){
        UIView.animate(withDuration: 0.02) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.84, alpha: 1)
        }
    }
    
    @objc func cancelHoldMaster(sender: UIButton){
        UIView.animate(withDuration: 0.02) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.84, alpha: 1)
        }
    }
    
    
    
    @objc func expandButton(sender: UIButton!) {
        let masterCenter = masterButton.center
        let masterCenterX = masterButton.center.x
        let masterCenterY = masterButton.center.y
        
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.9)
        

        scheduleCollectionView.panGestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: scheduleCollectionView)
        scheduleCollectionView.panGestureRecognizer.setTranslation(CGPoint(x: 0, y: 100), in: scheduleCollectionView)
        
        
        UIView.animate(withDuration: 0.02) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.84, alpha: 1)
        }
        
        //self.scheduleCollectionView.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)

        
        
        if(buttonDirection!){
            for button in collapsingButtonArray{
                self.view.insertSubview(button, belowSubview: masterButton)
            }
            
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.83, options: [.curveEaseInOut,.allowUserInteraction], animations: {
                
                collapsingButtonArray[0].center = CGPoint(x: masterCenterX, y: masterCenterY-125)
                collapsingButtonArray[1].center = CGPoint(x: masterCenterX-88.388, y: masterCenterY-88.388)
                collapsingButtonArray[2].center = CGPoint(x: masterCenterX-125, y: masterCenterY)
                
            }, completion: nil)
        }else{
            
            UIView.animate(withDuration: 0.2, animations: {
                
                collapsingButtonArray[0].center = masterCenter
                collapsingButtonArray[1].center = masterCenter
                collapsingButtonArray[2].center = masterCenter
                
            }, completion: { (finished: Bool) in
                for button in collapsingButtonArray{
                    button.removeFromSuperview()
                }
            })
        }
        buttonDirection = !(buttonDirection!)
    }
    
    // MARK: Database

    func loadSchedule(){
        print("Load Schedule")
        dailyScheduleTemp.removeAll()
        usersScheduleTemp.removeAll()
        upcomingSpecialDaysTemp.removeAll()
        
        
        let group = DispatchGroup()
        group.enter()
        
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            let formater = DateFormatter()
            formater.dateFormat = "MMdd"
            let dateKey = formater.string(from: Date())
            
            
            
            self?.ref.child("dates").observeSingleEvent(of: .value, with: { (snapshot) in
                let dates = snapshot.value as? [String:NSDictionary] ?? [:]
                var schedule = "regular"
                
                for (key,values) in dates{
                    let formater = DateFormatter()
                    formater.dateFormat = "MMdd"
                    let refDate = formater.date(from: key)!
                    
                    var todayDateDouble = Double(formater.string(from: Date())) ?? 0
                    var refDateDouble = Double(key) ?? 0
                    
                    if(refDateDouble < 700){ //uptill july is previous year
                        refDateDouble += 1200
                    }
                    if(todayDateDouble < 700){ //uptill july is previous year
                        todayDateDouble += 1200
                    }
                    if(refDateDouble - todayDateDouble > 0){
                        formater.dateFormat = "M/dd"
                        let dateFormatted = formater.string(from: refDate)
                        upcomingSpecialDaysTemp.append([dateFormatted,values["name"] ?? "falied",refDateDouble, values["schedule"] ?? "falied"])
                    }
                }
                upcomingSpecialDaysTemp = upcomingSpecialDaysTemp.sorted{($0[2] as! Double) < ($1[2]as! Double)}

                print("dfkjghlsjdkafnadf")
                print(upcomingSpecialDaysTemp)
                print("dfkjghlsjdkafnadf")
                
                if dates[dateKey] != nil{
                    let date = dates[dateKey]
                    schedule = date?["schedule"] as? String ?? "failed"
                    specialMessage = date?["reason"] as? String ?? "failed"
                }
                
                print(schedule)
                
                self?.ref.child("schedules").child(schedule).observeSingleEvent(of: .value, with: { (snapshot) in
                    let scheduleDict = snapshot.value as? NSDictionary ?? [:]
                    
                    for (key,value) in scheduleDict{
                        let key = key as? String ?? "noString"
                        if key != "name" {
                            let value = value as? NSDictionary ?? [:]
                            let startTime = value["start"] as? Double  ?? 0
                            let endTime = value["end"] as? Double  ?? 0
                            
                            var realStartTime = startTime
                            var realEndTime = endTime
                            if(startTime<6.3){ //times 1:00 - 6:29 are assumed to be PM 6:30 - 12:59 are AM
                                realStartTime = startTime + 12
                                realEndTime = endTime + 12
                            }
                            
                            dailyScheduleTemp.append([key,startTime,endTime,realStartTime,realEndTime])
                        }else{
                            scheduleName = value as? String ?? "kool"
                        }
                    }
                    
                    dailyScheduleTemp = dailyScheduleTemp.sorted{($0[3] as! Double) < ($1[3]as! Double)}
                    
                    let formater = NumberFormatter()
                    formater.decimalSeparator = ":"
                    formater.maximumFractionDigits = 2
                    formater.minimumFractionDigits = 2
                    formater.roundingMode = .halfUp
                    
                    for i in 0..<dailyScheduleTemp.endIndex {
                        dailyScheduleTemp[i][1] = formater.string(from: NSNumber(value: dailyScheduleTemp[i][1] as? Double ?? 0)) ?? "0"
                        dailyScheduleTemp[i][2] = formater.string(from: NSNumber(value: dailyScheduleTemp[i][2] as? Double ?? 0)) ?? "0"
                    }
                    
                    unNeededClasses = ["Early Bird A","Early Bird B","Period 1"]
                    
                    for period in dailyScheduleTemp{
                        let periodName = period[0]
                        if !(unNeededClasses.contains("\(periodName)")){
                            usersScheduleTemp.append(period)
                        }
                    }
                    
                    usersSchedule = usersScheduleTemp
                    dailySchedule = dailyScheduleTemp
                    upcomingSpecialDays = upcomingSpecialDaysTemp
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.scheduleCollectionView.reloadData()
                       // self?.scheduleDiscriptorLabel.text = scheduleName + " " + todaysDate
                    }
                    
                    
                    group.leave()
                    
                }) { (error) in
                    print(error.localizedDescription)
                    }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        group.notify(queue: .main) {
            self.timeTillNextUpdate = 0.001
            self.scheduleNewUpdate()
        }
    }
    
    
    
    func scheduleNewUpdate(){
        update?.cancel()
        
        update = DispatchWorkItem { [weak self] in
            //remember to go to MAIN thread to change UI label
            /*
             
             DispatchQueue.main.async { [weak self] in
                label.text = IDK What to say
             }

            */
            DispatchQueue.global(qos: .userInitiated).sync {
                let formater = DateFormatter()
                formater.dateFormat = "HH.mm"
                let currentTime = Double(formater.string(from: Date())) ?? 0
                
                let formaterSec = DateFormatter()
                formaterSec.dateFormat = "ss.SSS"
                let secPassed = Double(formaterSec.string(from: Date())) ?? 0
                self?.timeTillNextUpdate = 60 - secPassed
                
                if(usersSchedule[0][3] as? Double ?? 0 >= currentTime){
                    self?.currentPeriodIndex = -1

                    //change date
                    let formater = DateFormatter()
                    formater.dateFormat = "EEEE, M/d"
                    
                    DispatchQueue.main.async { [weak self] in
                       // self?.dateLabel.text = formater.string(from: Date())
                    }
                    
                    print("before school")
                    self?.setTimeToNextClass(endTime: "\(usersSchedule[0][3])")
                    print("first Class at\(self!.secondsToMinutes(seconds: self?.timeTillNextClass))")
                    
                    if((self?.timeTillNextClass as! Double) > 300.0){
                        // updates start again 5 minutes before class
                        self?.timeTillNextUpdate = (self!.timeTillNextClass! - 300.0)
                    }else{
                        //every minute updates
                        //display minutes to class start
                    }
                }
                else if(usersSchedule[usersSchedule.count - 1][4] as? Double ?? 0 <= currentTime){
                    print("school is over")
                    self?.setTimeToNextClass(endTime: "24.00")
                    self?.timeTillNextUpdate = self?.timeTillNextClass

                    print("next Update at end of day\(self!.secondsToMinutes(seconds: self?.timeTillNextClass))")
                }else{
                    for i in 0..<usersSchedule.count{
                        let period = usersSchedule[i]
                        self?.currentPeriodIndex = i
                        // timeIndex 3
                        if(currentTime < (period[3] as? Double ?? 0) ){
                            self?.tillEndOfCurrentBool = false
                            self?.setTimeToNextClass(endTime: "\(period[3])")
                            print("Time till period start: \(self!.secondsToMinutes(seconds: self?.timeTillNextClass!))")
                            break
                        }else if(currentTime < (period[4] as? Double ?? 0) ){
                            self?.tillEndOfCurrentBool = true
                            self?.setTimeToNextClass(endTime: "\(period[4])")
                            print("Time till period end: \(self!.secondsToMinutes(seconds: self?.timeTillNextClass!))")
                            break
                        }
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    self?.scheduleCollectionView.reloadData()
                }
            }
            self?.scheduleNewUpdate()
        }
        
        let formater = NumberFormatter()
        formater.decimalSeparator = ":"
        formater.maximumFractionDigits = 2
        formater.minimumFractionDigits = 2
        formater.roundingMode = .halfUp
        
        
        print("Time till next Update: \(timeTillNextUpdate!)")
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + abs(timeTillNextUpdate!),execute: update!)
    }
    
    func secondsToMinutes(seconds: Double?) -> String{
        let seconds = seconds ?? 0
        let minutes = seconds/60
        let numFormatter = NumberFormatter()
        numFormatter.roundingMode = .up
        numFormatter.maximumFractionDigits = 0
        
        return numFormatter.string(from: minutes as NSNumber) ?? "error"
    }
    
    
    func setTimeToNextClass (endTime: String){
        let formater = DateFormatter()
        formater.dateFormat = "HH.mm"
        let currentTime = Double(formater.string(from: Date())) ?? 0
        
        let startDouble = Double(currentTime)
        let endDouble = Double(endTime)
    
        let startInt = Double(Int(startDouble))
        let endInt = Double(Int(endDouble!))
    
        let secondsTimeStart = startInt*3600 + (startDouble - startInt)*6000
        let secondsTimeEnd = endInt*3600 + (endDouble! - endInt)*6000
    
        //subtract seconds already in minute
    
        let formaterSec = DateFormatter()
        formaterSec.dateFormat = "ss.SSS"
        let secPassed = Double(formaterSec.string(from: Date())) ?? 0
        self.timeTillNextClass =  (secondsTimeEnd - secondsTimeStart - secPassed)
    }
    
    
    // MARK: Collection Views

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersSchedule.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == usersSchedule.count {
            let cell = scheduleCollectionView.dequeueReusableCell(withReuseIdentifier: "UpcomingDaysCell", for: indexPath) as! UpcomingDaysCell
            for button in cell.buttons {
                button.layer.cornerRadius = 25
                button.backgroundColor = .main
            }

            for i in 0...2 {
                let button = cell.buttons[i]
                button.backgroundColor = .main
                button.layer.cornerRadius = 42.5
                let label = cell.labels[i]
                print(upcomingSpecialDays)
                print(i)
                if upcomingSpecialDays.count != 0 {
                    button.setTitle(upcomingSpecialDays[i][0] as? String, for: .normal)
                    button.titleLabel?.textAlignment = .center
                    label.text = upcomingSpecialDays[i][1] as? String
                }
            }
            
            cell.firstButtonPressed = {
                selectedButton = 0
                self.performSegue(withIdentifier: "toUpcomingSegue", sender: self)
            }
            
            cell.secondButtonPressed = {
                selectedButton = 1
                self.performSegue(withIdentifier: "toUpcomingSegue", sender: self)
            }
            
            cell.thirdButtonPressed = {
                selectedButton = 2
                self.performSegue(withIdentifier: "toUpcomingSegue", sender: self)
            }
            
            return cell 

        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TestCollectionViewCell
            
            cell.backgroundColor = .white
            cell.periodLabel.text = usersSchedule[indexPath.row][0] as? String
        
            
            if((self.currentPeriodIndex ?? -1) == indexPath.row){
                var ender = ""
                if(tillEndOfCurrentBool){
                    ender = " Minutes Left"
                }else{
                    ender = " Minutes Till Start"
                }
                cell.timeLabel.text = secondsToMinutes(seconds: self.timeTillNextClass ?? -1) + ender
            } else {
                cell.timeLabel.text = String(usersSchedule[indexPath.row][1] as? String ?? "e") + " - " + String(usersSchedule[indexPath.row][2] as? String ?? "w")
            }
            
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == usersSchedule.count {
            return CGSize(width: 374, height: 160)
        } else {
            return CGSize(width: 374, height: 90)
        }
    }
    
    //MARK: Drawer
    // The current state of the animation. This variable is changed only when an animation completes.
    
    // All of the currently running animators.
    private var runningAnimators = [UIViewPropertyAnimator]()
    
    /// The progress of each animator. This array is parallel to the `runningAnimators` array.
    private var animationProgress = [CGFloat]()
    
    private lazy var panRecognizer: InstantPanGestureRecognizer = {
        let recognizer = InstantPanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(popupViewPanned(recognizer:)))
        return recognizer
    }()
    
    // Animates the transition, if the animation is not already running.
    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        
        let screenSize = UIScreen.main.bounds.size

        let maxHeight = screenSize.height - 200
        let minHeight: CGFloat = 150
        
        let y = (screenSize.height - drawerHeightConstraint.constant)
        let height = max(y, minHeight)
        
        // ensure that the animators array is empty (which implies new animations need to be created)
        guard runningAnimators.isEmpty else { return }
        

        // an animator for the transition
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1, animations: {
            switch state {
            case .open:
                self.drawerHeightConstraint.constant = self.popupOffset
                self.titleHeader?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            case .closed:
                self.drawerHeightConstraint.constant = 150
                self.titleHeader?.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            }
            self.view.layoutIfNeeded()
            self.scrollViewDidScroll(self.scheduleCollectionView)
        })
        
        // the transition completion block
        transitionAnimator.addCompletion { position in
            
            // update the state
            switch position {
            case .start:
                currentState = state.opposite
            case .end:
                currentState = state
            case .current:
                ()
            }
            self.titleHeader?.layoutSublayers(of: self.titleHeader!.layer.sublayers![0])

            // manually reset the constraint positions
            switch currentState {
            case .open:
                self.drawerHeightConstraint.constant = self.popupOffset
                self.scheduleCollectionView.isScrollEnabled = true
                //self.scheduleCollectionView.isUserInteractionEnabled = true
                //self.panRecognizer.isEnabled = false
            case .closed:
                self.drawerHeightConstraint.constant = 150
               // self.scheduleCollectionView.isUserInteractionEnabled = false
            }
            
            // remove all running animators
            self.runningAnimators.removeAll()
        }
        
        // start all animators
        transitionAnimator.startAnimation()
        
        // keep track of all running animators
        runningAnimators.append(transitionAnimator)
    }
    
    @objc private func popupViewPanned(recognizer: UIPanGestureRecognizer) {
        
        let yVelocity = recognizer.velocity(in: drawerView).y
        
        switch recognizer.state {
        case .began:
            
            // start the animations
            animateTransitionIfNeeded(to: currentState.opposite, duration: 0.4)
            
            // pause all animations, since the next event may be a pan changed
            runningAnimators.forEach { $0.pauseAnimation() }
            
            // keep track of each animator's progress
            animationProgress = runningAnimators.map { $0.fractionComplete }
            
        case .changed:
            // variable setup
            let translation = recognizer.translation(in: drawerView)
            var fraction = -translation.y / popupOffset
            // adjust the fraction for the current state and reversed state
            if currentState == .open { fraction *= -1 }
            if runningAnimators[0].isReversed { fraction *= -1 }
            
            // apply the new fraction
            for (index, animator) in runningAnimators.enumerated() {
                animator.fractionComplete = fraction + animationProgress[index]
            }
            
        case .ended:
            
            // variable setup
            //let yVelocity = recognizer.velocity(in: scheduleCollectionView).y
            let shouldClose = yVelocity > 0
            
            // if there is no motion, continue all animations and exit early
            if yVelocity == 0 {
                runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
                break
            }
            
            // reverse the animations based on their current state and pan motion
            switch currentState {
            case .open:
                if shouldClose == runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed }}
                //if shouldClose && runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed } }
            case .closed:
                if shouldClose != runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed } }
               // if !shouldClose && runningAnimators[0].isReversed { runningAnimators.forEach { $0.isReversed = !$0.isReversed }}
            }
            
            // continue all animations
            runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
            
        default:
            ()
        }
    }
    
    
    
    
    // MARK: Seuge
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let masterCenter = masterButton.center
//        let masterCenterX = masterButton.center.x
//        let masterCenterY = masterButton.center.y
//
//        if(!buttonDirection!){
//            UIView.animate(withDuration: 0.2, animations: {
//
//                collapsingButtonArray[0].center = masterCenter
//                collapsingButtonArray[1].center = masterCenter
//                collapsingButtonArray[2].center = masterCenter
//
//            }, completion: { (finished: Bool) in
//                for button in collapsingButtonArray{
//                    button.removeFromSuperview()
//                }
//            })
//            buttonDirection = !(buttonDirection!)
//        }
        if segue.identifier == "toUpcomingSegue" {
            let destinationVC = segue.destination as! UpcomingViewController
            destinationVC.scheduleType = upcomingSpecialDays[selectedButton]
        }
        
    }
}


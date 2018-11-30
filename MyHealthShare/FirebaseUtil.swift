//
//  FirebaseUtil.swift
//  MyHealthShare
//
//  Created by 寺田 克彦 on 2018/11/30.
//  Copyright © 2018 beowulf-tech. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

open class FirebaseUtil {
    
    enum table: String
    {
        case users
        case healthData
    }

    enum keys: String
    {
        case nickname
        case team_id
        case stepCount
        case date
    }
    
    static public let shared = FirebaseUtil()
    private init(){}
    
    let db = Firestore.firestore()

    public struct Observables {
        
        fileprivate let usersSubject = PublishSubject<[User]>()
        var users: Observable<[User]> { return usersSubject }
        
        fileprivate let userSubject = PublishSubject<User>()
        var user: Observable<User> { return userSubject }

        fileprivate let healthDataSubject = PublishSubject<[HealthData]>()
        var healthData: Observable<[HealthData]> { return healthDataSubject }
    }
    public let observables = Observables()
    
    
    func add(nickName: String, team_id: String)
    {
        var ref: DocumentReference? = nil
        ref = db.collection(table.users.rawValue).addDocument(data: [
            keys.nickname.rawValue: nickName,
            keys.team_id.rawValue: team_id
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    func readUsers(team_id: String)
    {
        db.collection(table.users.rawValue).whereField(keys.team_id.rawValue, isEqualTo: team_id).getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    func read(nickName: String)
    {
        db.collection(table.users.rawValue).whereField(keys.nickname.rawValue, isEqualTo: nickName).getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    let user = User(document.data())
                    self.observables.userSubject.onNext(user)
                }
            }
        }
    }

    func addHealthData(nickName: String, stepCount: Int)
    {
        var ref: DocumentReference? = nil
        ref = db.collection(table.healthData.rawValue).addDocument(data: [
            keys.nickname.rawValue: nickName,
            keys.stepCount.rawValue: stepCount,
            keys.date.rawValue: Timestamp(date: Date())
            //"date": FieldValue.serverTimestamp()
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    func readHealthData(nickName: String)
    {
        db.collection(table.healthData.rawValue).whereField(keys.nickname.rawValue, isEqualTo: nickName).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var healthData = [HealthData]()
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    healthData.append(HealthData(document.data()))
                }
                self.observables.healthDataSubject.onNext(healthData)
            }
        }
    }
}

struct User : Codable
{
    var nickname : String
    var team_id : String
    
    init(_ dic: Dictionary<String, Any>) {
        self.nickname = dic[FirebaseUtil.keys.nickname.rawValue] as! String
        self.team_id = dic[FirebaseUtil.keys.team_id.rawValue] as! String
    }
}

struct HealthData : Codable
{
    var nickname : String
    var stepCount : Int?
    var date: String?
    
    init(_ dic: Dictionary<String, Any>) {
        self.nickname = dic[FirebaseUtil.keys.nickname.rawValue] as! String
        self.stepCount = dic[FirebaseUtil.keys.stepCount.rawValue] as? Int
    }
}

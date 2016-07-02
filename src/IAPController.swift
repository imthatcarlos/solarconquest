//
//  IAPController.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 8/13/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import StoreKit

class IAPController: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    class var sharedInstance: IAPController {
        struct Singleton {
            static let instance = IAPController()
        }
        
        return Singleton.instance
    }
    
    var parentScene: MapScene!
    var viewController: UIViewController!
    let productIdentifiers = Set(["solar_conquest_second_planet", "third_planet"])
    var productsDictionary = [String: SKProduct]()
    
    override init() {
        
    }
    
    func initialize(viewController: UIViewController, parentScene: MapScene) {
        self.viewController = viewController
        self.parentScene = parentScene
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    func requestProductData()
    {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers:
                self.productIdentifiers as Set<String>)
            request.delegate = self
            request.start()
        } else {
            let alert = UIAlertController(title: "In-App Purchases Not Enabled", message: "Please enable In App Purchase in Settings", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { alertAction in
                alert.dismissViewControllerAnimated(true, completion: nil)
                
                let url: NSURL? = NSURL(string: UIApplicationOpenSettingsURLString)
                if url != nil
                {
                    UIApplication.sharedApplication().openURL(url!)
                }
                
            }))
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { alertAction in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            self.viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        
        parentScene.iapEnabled = true
        var products = response.products
        
        if (products.count != 0) {
            for var i = 0; i < products.count; i++
            {
                let product = products[i]
                productsDictionary[product.productIdentifier] = product
            }

            parentScene.updatePrices(productsDictionary)
            
        } else {
            print("No products found")
        }
    }
    
    func buyProduct(productName: String){
        print("Sending the Payment Request to Apple");
        
        if productName == "RESTORE" {
            print("RESTORING!")
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
            return
        }
        
        let product = productsDictionary[productName]!
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment);
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
        print("Received Payment Transaction Response from Apple");
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .Purchased:
                print("Product Purchased");
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                parentScene.itemPurchased(transaction.payment.productIdentifier)
                break;
            case .Failed:
                print("Purchased Failed");
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                break;
            case .Restored:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                parentScene.itemPurchased(transaction.payment.productIdentifier)
                break
            default:
                break;
            }
        }
    }
}
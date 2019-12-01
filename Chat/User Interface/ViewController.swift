//
//  ViewController.swift
//  Chat
//
//  Created by Hovhannes Stepanyan on 11/30/19.
//  Copyright © 2019 Hovhannes Stepanyan. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import FirebaseAuth
import FirebaseFirestore

class ViewController: JSQMessagesViewController {

    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let currentUser = Auth.auth().currentUser!
        self.senderId = currentUser.uid
        self.senderDisplayName = currentUser.displayName ?? "Me"
        self.navigationController?.isNavigationBarHidden = false
        incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
        inputToolbar.contentView.rightBarButtonItem.setTitle(nil, for: .normal)
//        inputToolbar.contentView.rightBarButtonItem.setImage(#imageLiteral(resourceName: "arrow_right"), for: .normal)
        inputToolbar.contentView.rightBarButtonItem.setTitle("Send", for: .normal)
        inputToolbar.contentView.textView.placeHolder = "Chat"
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        collectionView?.collectionViewLayout.springinessEnabled = false
        automaticallyScrollsToMostRecentMessage = true
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    func getData() {
        Firestore.firestore().collection("messages")
            .addSnapshotListener {[weak self] snapshot, error in
                guard let weakSelf = self else { return }
                if let error = error {
                    
                } else {
                    snapshot?.documentChanges.forEach({ doc in
                        let dict = doc.document.data()
                        let message = weakSelf.convertDictionaryToMessage(dict)
                        weakSelf.messages.append(message)
                        weakSelf.finishSendingMessage(animated: true)
                    })
                }
        }
    }
    
    private func convertDictionaryToMessage(_ dict: [String: Any]) -> JSQMessage {
        let senderId = dict["senderId"] as! String
        let senderDisplayName = dict["senderDisplayName"] as! String
        let ts = dict["date"] as! Timestamp
        let text = dict["text"] as! String
        return JSQMessage.init(senderId: senderId, senderDisplayName: senderDisplayName, date: ts.dateValue(), text: text)
    }

    // MARK: - JSQMessagesViewController method overrides
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        /* Отправляем текстовое сообщение */
        // TODO: send mesage
        var dict = [String: Any]()
        dict["senderId"] = senderId
        dict["senderDisplayName"] = senderDisplayName
        dict["date"] = Timestamp(date: date)
        dict["text"] = text
        Firestore.firestore().collection("messages").document().setData(dict)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let imagePickerController: UIImagePickerController = UIImagePickerController()
//        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerController.SourceType.savedPhotosAlbum
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    //MARK: - JSQMessages CollectionView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
        return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        if (indexPath.item % 3 == 0) {
            let message = self.messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = self.messages[indexPath.item]
        
        if !message.isMediaMessage {
            var tintColor: UIColor = UIColor()
            if message.senderId == self.senderId {
                tintColor = UIColor.white
            } else {
                tintColor = UIColor.black
            }
            
            cell.textView.textColor = tintColor
            cell.textView.linkTextAttributes = [.foregroundColor: tintColor]
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        if message.senderId == self.senderId {
            return nil
        }
        
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        let currentMessage = self.messages[indexPath.item]
        if currentMessage.senderId == self.senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }

}


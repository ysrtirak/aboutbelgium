
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require('firebase-admin');
admin.initializeApp();

// Mesaj gönderildiğinde tetiklenecek fonksiyon
exports.sendNotificationOnNewMessage = onDocumentCreated(
  'facetofacechat/{chatRoomId}/messages/{messageId}',
  async (event) => {
    const messageSnapshot = event.data;
    const messageData = messageSnapshot.data();
    const chatRoomId = event.params.chatRoomId;
    const senderId = messageData.senderId;
    const receiverId = messageData.receiverId;

    console.log('Event Data:', messageData);
    console.log('Chat Room ID:', chatRoomId);
    console.log('Sender ID:', senderId);
    console.log('Receiver ID:', receiverId);

    if (!receiverId) {
      console.error('Receiver ID is not valid:', receiverId);
      return;
    }

    const userSnapshot = await admin.firestore().collection('users').doc(receiverId).get();
    if (!userSnapshot.exists) {
      console.error('User does not exist:', receiverId);
      return;
    }

    const userSenderSnapshot = await admin.firestore().collection('users').doc(senderId).get();
    if (!userSenderSnapshot.exists) {
      console.error('User does not exist:', senderId);
      return;
    }
    const receiverData = userSnapshot.data();
    const receiverToken = receiverData.fcmToken;

    const senderData = userSenderSnapshot.data();
    const senderUserName = senderData.userName

    if (!receiverToken) {
      console.error('Receiver token is not available for user:', receiverId);
      return;
    }

//    const chatRoomDoc = await admin.firestore().collection('facetofacechat').doc(chatRoomId).get();
//    if (chatRoomDoc.exists && chatRoomDoc.data().activeUsers && chatRoomDoc.data().activeUsers.includes(receiverId)) {
//      console.log('User is active in chat room, no notification sent.');
//      return;
//    }

    const message = {
      notification: {
        title: senderUserName,
        body: messageData.text,
      },
      token: receiverToken,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Notification sent successfully:', response);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  }
);








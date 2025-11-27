#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
    components SRTreeC;
    components RandomC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
    components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
   	 components PrintfC;
#endif
    components MainC, ActiveMessageC, SerialActiveMessageC, LedsC;
    components new TimerMilliC() as Led0TimerC;
    components new TimerMilliC() as Led1TimerC;
    components new TimerMilliC() as Led2TimerC;
    components new TimerMilliC() as RoutingMsgTimerC;
    components new TimerMilliC() as LostTaskTimerC;

	components new TimerMilliC() as EpochTimerC; //ADDED
    
    components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
    components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
    /* Notify components removed - not used by TinyAggregation */
#ifdef SERIAL_EN
    components new SerialAMSenderC(AM_NOTIFYPARENTMSG);
    components new SerialAMReceiverC(AM_NOTIFYPARENTMSG);
#endif
    components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
    /* Notify queues removed: TinyAggregation doesn't use notify parent messages */
    
    SRTreeC.Random->RandomC;
    SRTreeC.Boot->MainC.Boot;
    
    SRTreeC.RadioControl -> ActiveMessageC;
    SRTreeC.Leds-> LedsC;
    
    SRTreeC.Led0Timer-> Led0TimerC;
    SRTreeC.Led1Timer-> Led1TimerC;
    SRTreeC.Led2Timer-> Led2TimerC;
    SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
    
	SRTreeC.EpochTimer->EpochTimerC; //ADDED

    SRTreeC.RoutingPacket->RoutingSenderC.Packet;
    SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
    SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
    SRTreeC.RoutingReceive->RoutingReceiverC.Receive;
    
    /* Notify bindings removed */
    
#ifdef SERIAL_EN    
    SRTreeC.SerialReceive->SerialAMReceiverC.Receive;
    SRTreeC.SerialAMSend->SerialAMSenderC.AMSend;
    SRTreeC.SerialAMPacket->SerialAMSenderC.AMPacket;
    SRTreeC.SerialPacket->SerialAMSenderC.Packet;
    SRTreeC.SerialControl->SerialActiveMessageC;
#endif
    SRTreeC.RoutingSendQueue->RoutingSendQueueC;
    SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;
    SRTreeC.NotifySendQueue->NotifySendQueueC;
    SRTreeC.NotifyReceiveQueue->NotifyReceiveQueueC;
    
}

configuration SRTreeAppC @safe() { }
implementation{
    components SRTreeC;
    components RandomC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
    components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
   	 components PrintfC;
#endif
    components MainC, ActiveMessageC, SerialActiveMessageC, LedsC;
    components new TimerMilliC() as Led0TimerC;
    components new TimerMilliC() as Led1TimerC;
    components new TimerMilliC() as Led2TimerC;
    components new TimerMilliC() as RoutingMsgTimerC;
    
    components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
    components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;

#ifdef SERIAL_EN
    components new SerialAMSenderC(AM_NOTIFYPARENTMSG);
    components new SerialAMReceiverC(AM_NOTIFYPARENTMSG);
#endif
    components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
    
    SRTreeC.Random->RandomC;
    SRTreeC.Boot->MainC.Boot;
    
    SRTreeC.RadioControl -> ActiveMessageC;
    SRTreeC.Leds-> LedsC;
    
    SRTreeC.Led0Timer-> Led0TimerC;
    SRTreeC.Led1Timer-> Led1TimerC;
    SRTreeC.Led2Timer-> Led2TimerC;
    SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
    
    SRTreeC.RoutingPacket->RoutingSenderC.Packet;
    SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
    SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
    SRTreeC.RoutingReceive->RoutingReceiverC.Receive;
    
    
#ifdef SERIAL_EN    
    SRTreeC.SerialReceive->SerialAMReceiverC.Receive;
    SRTreeC.SerialAMSend->SerialAMSenderC.AMSend;
    SRTreeC.SerialAMPacket->SerialAMSenderC.AMPacket;
    SRTreeC.SerialPacket->SerialAMSenderC.Packet;
    SRTreeC.SerialControl->SerialActiveMessageC;
#endif
    SRTreeC.RoutingSendQueue->RoutingSendQueueC;
    SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;
    
}


#include "SimpleRoutingTree.h"
#ifdef PRINTFDBG_MODE
    #include "printf.h"
#endif


module SRTreeC
{
    uses interface Boot;
    uses interface Leds;
    uses interface SplitControl as RadioControl;
#ifdef SERIAL_EN
    uses interface SplitControl as SerialControl;
#endif

	uses interface Packet as RoutingPacket;
	uses interface AMSend as RoutingAMSend;
	uses interface AMPacket as RoutingAMPacket;

#ifdef SERIAL_EN
    uses interface AMSend as SerialAMSend;
    uses interface AMPacket as SerialAMPacket;
    uses interface Packet as SerialPacket;
#endif
	uses interface Timer<TMilli> as Led0Timer;
	uses interface Timer<TMilli> as Led1Timer;
	uses interface Timer<TMilli> as Led2Timer;
	uses interface Timer<TMilli> as RoutingMsgTimer;

	uses interface Receive as RoutingReceive;

	uses interface PacketQueue as RoutingSendQueue;
	uses interface PacketQueue as RoutingReceiveQueue;

	// aggregation interfaces
	uses interface Random as Random;

	uses interface PacketQueue as AggQuerySendQueue;
	uses interface PacketQueue as AggQueryReceiveQueue;

	uses interface Packet as AggMinPacket;
	uses interface AMPacket as AggMinAMPacket;
	uses interface AMSend as AggMinAMSend;
	uses interface Receive as AggMinReceive;
	uses interface PacketQueue as AggMinSendQueue;
	uses interface PacketQueue as AggMinReceiveQueue;

/*
	uses interface Packet as AggSumPacket;
	uses interface AMSend as AggSumAMSend;
	uses interface Receive as AggSumReceive;
	uses interface PacketQueue as AggSumSendQueue;
	uses interface PacketQueue as AggSumReceiveQueue;

	uses interface Packet as AggAvgPacket;
	uses interface AMSend as AggAvgAMSend;
	uses interface Receive as AggAvgReceive;
	uses interface PacketQueue as AggAvgSendQueue;
	uses interface PacketQueue as AggAvgReceiveQueue;
*/
	uses interface Timer<TMilli> as EpochTimer;

}
implementation
{
	uint16_t  roundCounter;

	message_t radioRoutingSendPkt;
	message_t serialPkt;

    int16_t curdepth;
    int16_t parentID=-1;
    
	//ADDED
    uint8_t aggType=0;
    uint16_t sample=0;
    uint16_t epochCounter=0;
	uint16_t agg_min=0xFFFF;
	uint32_t agg_sum=0;
	uint16_t agg_count=0;
	//END ADDED
	bool RoutingSendBusy = FALSE;

	void setRoutingSendBusy(bool state) {
		atomic { RoutingSendBusy = state; }
		if (state == TRUE) {
			call Leds.led0On();
			call Led0Timer.startOneShot(TIMER_LEDS_MILLI);
		} else {
			// LED off is handled by the Led0Timer fired event
		}
	}

	task void sendRoutingTask();
	task void receiveRoutingTask();
	task void sendAggMinTask();
	task void receiveAggMinTask();
	//task void sendAggSumTask();
	//task void receiveAggSumTask();
	//task void sendAggAvgTask();
	//task void receiveAggAvgTask();



#ifdef SERIAL_EN
	bool serialBusy = FALSE;
#endif

/*
#ifdef SERIAL_EN
    uses interface AMSend as SerialAMSend;
    uses interface AMPacket as SerialAMPacket;
    uses interface Packet as SerialPacket;
#endif
*/
    event void Boot.booted()
    {
   	 /////// arxikopoiisi radio kai serial
   	 call RadioControl.start();
   	 
   	 roundCounter =0;
   	 
   	 if(TOS_NODE_ID==0)
   	 {
#ifdef SERIAL_EN
   		 call SerialControl.start();
#endif
   		 curdepth=0;
   		 parentID=0;
   		 dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
#ifdef PRINTFDBG_MODE
   		 printf("Booted NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
   		 printfflush();
#endif
   	 }
   	 else
   	 {
   		 curdepth=-1;
   		 parentID=-1;
   		 dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
#ifdef PRINTFDBG_MODE
   		 printf("Booted NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
   		 printfflush();
#endif
   	 }
    }
    
    event void RadioControl.startDone(error_t err)
    {
   	 if (err == SUCCESS)
   	 {
   		 dbg("Radio" , "Radio initialized successfully!!!\n");
#ifdef PRINTFDBG_MODE
   		 printf("Radio initialized successfully!!!\n");
   		 printfflush();
#endif
   		 
   		 //call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI);
   		 //call RoutingMsgTimer.startPeriodic(TIMER_PERIOD_MILLI);
   		 //call LostTaskTimer.startPeriodic(SEND_CHECK_MILLIS);
   		 if (TOS_NODE_ID==0)
   		 {
   			 call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
   		 }
   	 }
   	 else
   	 {
   		 dbg("Radio" , "Radio initialization failed! Retrying...\n");
#ifdef PRINTFDBG_MODE
   		 printf("Radio initialization failed! Retrying...\n");
   		 printfflush();
#endif
   		 call RadioControl.start();
   	 }
    }
    
    event void RadioControl.stopDone(error_t err)
    {
   	 dbg("Radio", "Radio stopped!\n");
#ifdef PRINTFDBG_MODE
   	 printf("Radio stopped!\n");
   	 printfflush();
#endif
    }
    event void SerialControl.startDone(error_t err)
    {
   	 if (err == SUCCESS)
   	 {
   		 dbg("Serial" , "Serial initialized successfully! \n");
#ifdef PRINTFDBG_MODE
   		 printf("Serial initialized successfully! \n");
   		 printfflush();
#endif
   		 //call RoutingMsgTimer.startPeriodic(TIMER_PERIOD_MILLI);
   	 }
   	 else
   	 {
   		 dbg("Serial" , "Serial initialization failed! Retrying... \n");
#ifdef PRINTFDBG_MODE
   		 printf("Serial initialization failed! Retrying... \n");
   		 printfflush();
#endif
   		 call SerialControl.start();
   	 }
    }
    event void SerialControl.stopDone(error_t err)
    {
   	 dbg("Serial", "Serial stopped! \n");
#ifdef PRINTFDBG_MODE
   	 printf("Serial stopped! \n");
   	 printfflush();
#endif
    }
    
    
    event void RoutingMsgTimer.fired()
    {
   	 message_t tmp;
   	 error_t enqueueDone;
   	 
   	 RoutingMsg* mrpkt;
   	 dbg("SRTreeC", "RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");
#ifdef PRINTFDBG_MODE
   	 printfflush();
   	 printf("RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");
   	 printfflush();
#endif
   	 if (TOS_NODE_ID==0)
   	 {
   		 roundCounter+=1;
   		 
   		 dbg("SRTreeC", "\n ##################################### \n");
   		 dbg("SRTreeC", "#######   ROUND   %u	############## \n", roundCounter);
   		 dbg("SRTreeC", "#####################################\n");
   		 //ADDED
   		 //generate random aggType
   		 //aggType= (call Random.rand16() %3) +1; // 1=MIN,2=SUM,3=AVG
		aggType=1;
   		 //call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI);
   	 }
   	 
   	 if(call RoutingSendQueue.full())
   	 {
#ifdef PRINTFDBG_MODE
   		 printf("RoutingSendQueue is FULL!!! \n");
   		 printfflush();
#endif
   		 return;
   	 }
   	 
   	 
   	 mrpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&tmp, sizeof(RoutingMsg)));
   	 if(mrpkt==NULL)
   	 {
   		 dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");
#ifdef PRINTFDBG_MODE
   		 printf("RoutingMsgTimer.fired(): No valid payload... \n");
   		 printfflush();
#endif
   		 return;
   	 }
   	 atomic{
   	 mrpkt->senderID=TOS_NODE_ID;
   	 mrpkt->depth = curdepth;
   	 mrpkt->aggType=aggType; //ADDED
   	 }
   	 dbg("SRTreeC" , "Sending RoutingMsg... \n");

#ifdef PRINTFDBG_MODE
   	 printf("NodeID= %d : RoutingMsg sending...!!!! \n", TOS_NODE_ID);
   	 printfflush();
#endif   	 
   	 call RoutingAMPacket.setDestination(&tmp, AM_BROADCAST_ADDR);
   	 call RoutingPacket.setPayloadLength(&tmp, sizeof(RoutingMsg));
   	 
   	 enqueueDone=call RoutingSendQueue.enqueue(tmp);
   	 
   	 if( enqueueDone==SUCCESS)
   	 {
   		 if (call RoutingSendQueue.size()==1)
   		 {
   			 dbg("SRTreeC", "SendTask() posted!!\n");
#ifdef PRINTFDBG_MODE
   			 printf("SendTask() posted!!\n");
   			 printfflush();
#endif
   			 post sendRoutingTask();
   		 }
   		 
   		 dbg("SRTreeC","RoutingMsg enqueued successfully in SendingQueue!!!\n");
#ifdef PRINTFDBG_MODE
   		 printf("RoutingMsg enqueued successfully in SendingQueue!!!\n");
   		 printfflush();
#endif
   	 }
   	 else
   	 {
   		 dbg("SRTreeC","RoutingMsg failed to be enqueued in SendingQueue!!!");
#ifdef PRINTFDBG_MODE   		 
   		 printf("RoutingMsg failed to be enqueued in SendingQueue!!!\n");
   		 printfflush();
#endif
   	 }   	 
    }
    
    event void Led0Timer.fired()
    {
   	 call Leds.led0Off();
    }
    event void Led1Timer.fired()
    {
   	 call Leds.led1Off();
    }
    event void Led2Timer.fired()
    {
   	 call Leds.led2Off();
    }
    
    event void RoutingAMSend.sendDone(message_t * msg , error_t err)
    {
   	 dbg("SRTreeC", "A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
   	 printf("A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
   	 printfflush();
#endif
   	 
   	 dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
   	 printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
   	 printfflush();
#endif
   	 setRoutingSendBusy(FALSE);
   	 
   	 if(!(call RoutingSendQueue.empty()))
   	 {
   		 post sendRoutingTask();
   	 }
	 setRoutingSendBusy(FALSE);
   	 //call Leds.led0Off();
    
   	 
    }
    
    
    event void SerialAMSend.sendDone(message_t* msg , error_t err)
    {
   	 if ( &serialPkt == msg)
   	 {
   		 dbg("Serial" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
   		 printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
   		 printfflush();
#endif
   		 
   		 //call Leds.led2Off();
   	 }
    }
    
    
    /* Notify receive removed */
//    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
    event message_t* RoutingReceive.receive( message_t * msg , void * payload, uint8_t len)
    {
   	 error_t enqueueDone;
   	 message_t tmp;
   	 uint16_t msource;
   	 
   	 msource =call RoutingAMPacket.source(msg);
   	 
    	dbg("SRTreeC", "### RoutingReceive.receive() start ##### \n");
    	dbg("SRTreeC", "Something received (src=%u, len=%u)\n", msource, len);
   	 //dbg("SRTreeC", "Something received!!!\n");
#ifdef PRINTFDBG_MODE
    	 printf("Something Received!!!, len = %u , rm=%u\n", len, sizeof(RoutingMsg));
    	 printfflush();
#endif
   	 //call Leds.led1On();
   	 //call Led1Timer.startOneShot(TIMER_LEDS_MILLI);
   	 
   	 //if(len!=sizeof(RoutingMsg))
   	 //{
   		 //dbg("SRTreeC","\t\tUnknown message received!!!\n");
//#ifdef PRINTFDBG_MODE
   		 //printf("\t\t Unknown message received!!!\n");
   		 //printfflush();
//#endif
   		 //return msg;
   	 //}
   	 
   	 atomic{
   	 memcpy(&tmp,msg,sizeof(message_t));
   	 //tmp=*(message_t*)msg;
   	 }
   	 enqueueDone=call RoutingReceiveQueue.enqueue(tmp);
   	 if(enqueueDone == SUCCESS)
   	 {
#ifdef PRINTFDBG_MODE
   		 printf("posting receiveRoutingTask()!!!! \n");
   		 printfflush();
#endif
   		 post receiveRoutingTask();
   	 }
   	 else
   	 {
   		 dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");
#ifdef PRINTFDBG_MODE
   		 printf("RoutingMsg enqueue failed!!! \n");
   		 printfflush();
#endif   		 
   	 }
   	 
   	 //call Leds.led1Off();
   	 
   	 dbg("SRTreeC", "### RoutingReceive.receive() end ##### \n");
   	 return msg;
    }
    /*
    event message_t* SerialReceive.receive(message_t* msg , void* payload , uint8_t len)
    {
   	 // when receiving from serial port
   	 dbg("Serial","Received msg from serial port \n");
#ifdef PRINTFDBG_MODE
   	 printf("Reveived message from serial port \n");
   	 printfflush();
#endif
   	 return msg;
    }
    */
    ////////////// Tasks implementations //////////////////////////////
    
    
    task void sendRoutingTask()
    {
   	 //uint8_t skip;
   	 uint8_t mlen;
   	 uint16_t mdest;
   	 error_t sendDone;
   	 //message_t radioRoutingSendPkt;
   	 
#ifdef PRINTFDBG_MODE
   	 printf("SendRoutingTask(): Starting....\n");
   	 printfflush();
#endif
   	 if (call RoutingSendQueue.empty())
   	 {
   		 dbg("SRTreeC","sendRoutingTask(): Q is empty!\n");
#ifdef PRINTFDBG_MODE   	 
   		 printf("sendRoutingTask():Q is empty!\n");
   		 printfflush();
#endif
   		 return;
   	 }
	dbg("Epoch","Start epoch timer for node %d \n", TOS_NODE_ID);
   	call EpochTimer.startPeriodicAt(EPOCH_PERIOD_MILLI - (curdepth*WINDOW_MILLI),EPOCH_PERIOD_MILLI);
   	 
   	 if(RoutingSendBusy)
   	 {
   		 dbg("SRTreeC","sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
#ifdef PRINTFDBG_MODE
   		 printf(    "sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
   		 printfflush();
#endif
   		 return;
   	 }
   	 
   	 radioRoutingSendPkt = call RoutingSendQueue.dequeue();
   	 
   	 //call Leds.led2On();
   	 //call Led2Timer.startOneShot(TIMER_LEDS_MILLI);
   	 mlen= call RoutingPacket.payloadLength(&radioRoutingSendPkt);
   	 mdest=call RoutingAMPacket.destination(&radioRoutingSendPkt);
   	 if(mlen!=sizeof(RoutingMsg))
   	 {
   		 dbg("SRTreeC","\t\tsendRoutingTask(): Unknown message!!!\n");
#ifdef PRINTFDBG_MODE
   		 printf("\t\tsendRoutingTask(): Unknown message!!!!\n");
   		 printfflush();
#endif
   		 return;
   	 }
   	 sendDone=call RoutingAMSend.send(mdest,&radioRoutingSendPkt,mlen);
   	 
   	 if ( sendDone== SUCCESS)
   	 {
   		 dbg("SRTreeC","sendRoutingTask(): Send returned success!!!\n");
#ifdef PRINTFDBG_MODE
   		 printf("sendRoutingTask(): Send returned success!!!\n");
   		 printfflush();
#endif
   		 setRoutingSendBusy(TRUE);
   	 }
   	 else
   	 {
   		 dbg("SRTreeC","send failed!!!\n");
#ifdef PRINTFDBG_MODE
   		 printf("SendRoutingTask(): send failed!!!\n");
#endif
   		 //setRoutingSendBusy(FALSE);
   	 }
    }
    /**
     * dequeues a message and sends it
     */
	//ADDED - REMOVED
    /* sendNotifyTask removed - notify parent messages not used */
    ////////////////////////////////////////////////////////////////////
    //*****************************************************************/
    ///////////////////////////////////////////////////////////////////
    /**
     * dequeues a message and processes it
     */
    
    task void receiveRoutingTask()
    {
   	 message_t tmp;
   	 uint8_t len;
   	 message_t radioRoutingRecPkt;
   	 
#ifdef PRINTFDBG_MODE
   	 printf("ReceiveRoutingTask():received msg...\n");
   	 printfflush();
#endif
   	 radioRoutingRecPkt= call RoutingReceiveQueue.dequeue();
   	 
   	 len= call RoutingPacket.payloadLength(&radioRoutingRecPkt);
   	 
   	 dbg("SRTreeC","ReceiveRoutingTask(): len=%u \n",len);
#ifdef PRINTFDBG_MODE
   	 printf("ReceiveRoutingTask(): len=%u!\n",len);
   	 printfflush();
#endif
   	 // processing of radioRecPkt
   	 
   	 // pos tha xexorizo ta 2 diaforetika minimata???
   			 
	if (len == sizeof(RoutingMsg)) {
		RoutingMsg * mpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));
		if(mpkt==NULL)
		{
			return;
		}
		dbg("SRTreeC", "receiveRoutingTask():senderID= %d , depth= %d , aggType= %d \n", mpkt->senderID, mpkt->depth, mpkt->aggType);
#ifdef PRINTFDBG_MODE
		printf("NodeID= %d , RoutingMsg received! \n", TOS_NODE_ID);
		printf("receiveRoutingTask():senderID= %d , depth= %d \n", mpkt->senderID, mpkt->depth);
		printfflush();
#endif

		if ((parentID < 0) || (parentID >= 65535)) {
			// first time parent assignment, no rerouting afterwards
			parentID = call RoutingAMPacket.source(&radioRoutingRecPkt);
			curdepth = mpkt->depth + 1;
			aggType = mpkt->aggType;
			if (TOS_NODE_ID != 0){ 
				call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
			}
			dbg("printTopology", "NodeID %d: parentID= %d , curdepth= %d , aggType= %d \n", TOS_NODE_ID, parentID, curdepth, aggType);
		}
	}


}
#ifdef PRINTFDBG_MODE

   	 printf("A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
#endif

	event void EpochTimer.fired(){
		uint16_t temp;
		message_t out;
		error_t enqueueDone;
		AggregationMin* am;
		epochCounter += 1;
		if(epochCounter == 1 ){
			sample = (call Random.rand16() % 60) + 1; // random sample between 1 and 60
		}else{
			sample = (sample * ((call Random.rand16() % 40) + 80)) / 100; // * 0.8 to 1.2
			if(sample > 60){
				sample = 60;
			}
		}
		dbg("Sample","Sample generated: %u in Node %d\n", sample, TOS_NODE_ID);
		if(TOS_NODE_ID !=0){
			if(aggType == AGGREGATION_TYPE_MIN){ // MIN
			am = (AggregationMin*) call AggMinPacket.getPayload(&out, sizeof(AggregationMin));
			if (am == NULL) {return; }

			if(sample < agg_min){
				temp = sample;
				agg_min = sample;
			}else{
				temp = agg_min;
			}
			dbg("Min","Node %d: sample=%u , agg_min=%u \n", TOS_NODE_ID, sample, agg_min);
			atomic{
				am->minVal = temp;
				am->epoch = epochCounter;
				am->senderID = TOS_NODE_ID;
			}
				
			dbg("SentAggMin", "EpochTimer.fired(): Sending MIN aggregation message, epoch=%u, minVal=%u, sample=%u\n", am->epoch, am->minVal, sample);
			/* don't send if we don't have a parent yet */
			if ((parentID < 0) || (parentID == 0xFFFF)) {
				dbg("Epoch","EpochTimer.fired(): parent not set, skipping AggMin send on node %d\n", TOS_NODE_ID);
				return;
			}
			call AggMinAMPacket.setDestination(&out, parentID);
			call AggMinPacket.setPayloadLength(&out, sizeof(AggregationMin));
			enqueueDone=call AggMinSendQueue.enqueue(out);
		
			if( enqueueDone==SUCCESS){
				post sendAggMinTask();
				dbg("Epoch","MIN aggregation message enqueued successfully in SendingQueue!!!\n");	
			}
			}else if(aggType == AGGREGATION_TYPE_SUM){ // SUM
				// send sum aggregation message
			}
			else if(aggType == AGGREGATION_TYPE_AVG){ // AVG
				// send avg aggregation message
			}
		}else if(TOS_NODE_ID == 0) {
			// root: finalize and print
			if (aggType == AGGREGATION_TYPE_MIN) dbg("Results","AGG RESULT epoch=%u MIN=%u \n", epochCounter, agg_min);
			else if (aggType == AGGREGATION_TYPE_SUM) dbg("Results","AGG RESULT epoch=%u SUM=%u\n", epochCounter, agg_sum);
			else if (aggType == AGGREGATION_TYPE_AVG) { uint32_t avg = (agg_count>0)? (agg_sum/agg_count) : 0; dbg("Results","AGG RESULT epoch=%u AVG=%lu sum=%u count=%u\n", epochCounter, avg, agg_sum, agg_count); }
		}
		// reset aggregation variables
		agg_min = 0xFFFF;
		agg_sum = 0;
		agg_count = 0;
	}

	task void sendAggMinTask()
    {
   	 //uint8_t skip;
   	 uint16_t mlen;
   	 uint16_t mdest;
   	 error_t sendDone;
   	 message_t toSend;
	 AggregationMin* agg;

   	 if (call AggMinSendQueue.empty())
   	 {
   		 dbg("SentAggMin","sendAggMinTask(): Q is empty!\n");
#ifdef PRINTFDBG_MODE   	 
   		 printf("sendAggMinTask():Q is empty!\n");
   		 printfflush();
#endif
   		 return;
   	 }
   	 
   	 toSend = call AggMinSendQueue.dequeue();
   	 
   	 //call Leds.led2On();
   	 //call Led2Timer.startOneShot(TIMER_LEDS_MILLI);
	mdest=call AggMinAMPacket.destination(&toSend);
 	 mlen= call AggMinPacket.payloadLength(&toSend);

	 dbg("SentAggMin","Min Value to send in packet min %d\n", ((AggregationMin*)call AggMinPacket.getPayload(&toSend, mlen))->minVal);
   	 if(mlen!=sizeof(AggregationMin))
   	 {
   		 dbg("SentAggMin","\t\tsendAggMinTask(): Unknown message!!!\n");
   		 return;
   	 }
   	 
   	  agg = (AggregationMin*)call AggMinPacket.getPayload(&toSend, mlen);
   	 if (agg == NULL) {
   	 	 dbg("SentAggMin","sendAggMinTask(): getPayload returned NULL\n");
   	 	 return;
   	 }
   	 
	 dbg("SentAggMin","Min Value to send in packet min %d\n", agg->minVal);
		 dbg("SentAggMin","sendAggMinTask(): sending to dest=%u len=%u\n", mdest, mlen);
   	 sendDone=call AggMinAMSend.send(mdest,&toSend,mlen);
   	 
   	 if ( sendDone== SUCCESS)
   	 {
   		dbg("SentAggMin","sendAggMinTask success node %d to parent %d\n", TOS_NODE_ID, mdest);

   	 }
   	 else
   	 {
   		 dbg("SentAggMin","sendAggMinTask failed node %d to parent %d\n", TOS_NODE_ID, mdest);
#ifdef PRINTFDBG_MODE
   		 printf("sendAggMinTask(): send failed!!!\n");
#endif
   		 //setRoutingSendBusy(FALSE);
   	 }
    }

	event message_t* AggMinReceive.receive( message_t * msg , void * payload, uint8_t len)
    {
   	 error_t enqueueDone;
   	 message_t tmp;
   	 uint16_t msource;
   	 dbg("ReceiveAggMin", "### AggMinReceive.receive() start ##### \n");
   	 msource =call AggMinAMPacket.source(msg);

    dbg("ReceiveAggMin", "AggMin received (src=%u, len=%u)\n", msource, len);
   	 
   	 atomic{
   	 memcpy(&tmp,msg,sizeof(message_t));
   	 //tmp=*(message_t*)msg;
   	 }
   	 enqueueDone=call AggMinReceiveQueue.enqueue(tmp);
   	 if(enqueueDone == SUCCESS)
   	 {
   		post receiveAggMinTask();
   	 }
   	 else
   	 {
   		 dbg("Epoch","AggMin enqueue failed!!! \n");
#ifdef PRINTFDBG_MODE
   		 printf("AggMin enqueue failed!!! \n");
   		 printfflush();
#endif   		 
   	 }
   	 dbg("Epoch", "### AggMinReceive.receive() end ##### \n");
   	 return msg;
    }

	task void receiveAggMinTask()
    {
	AggregationMin * mpkt;
   	message_t tmp;
   	uint16_t len;
   	message_t msg;

   	if(call AggMinReceiveQueue.empty()) {
   		dbg("ReceiveAggMin","receiveAggMinTask(): Queue is empty!\n");
   		return;
   	}
   	 
   	 msg= call AggMinReceiveQueue.dequeue();
   	 
   	 len= call AggMinPacket.payloadLength(&msg);
   	 
   	 dbg("Epoch","ReceiveAggMinTask(): len=%u \n",len);
	 
	if (len == sizeof(AggregationMin)) {
		mpkt = (AggregationMin*) (call AggMinPacket.getPayload(&msg,len));
		if (mpkt == NULL) {
			dbg("ReceiveAggMin","receiveAggMinTask() getPayload returned NULL\n");
			return;
		}
		if (mpkt->epoch != epochCounter) {
			dbg("Epoch","receiveAggMinTask() from diff epoch \n");
			return;
		}
		dbg("ReceiveAggMin", "receiveAggMinTask():senderID= %d, minVal=%u, epoch=%u \n", mpkt->senderID, mpkt->minVal, mpkt->epoch);
		agg_min = (mpkt->minVal < agg_min) ? mpkt->minVal : agg_min;
	}	

	}

	event void AggMinAMSend.sendDone(message_t * msg , error_t err)
    {
   	 dbg("SentAggMin", "A Min package sent... %s \n",(err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
   	 printf("A Min package sent... %s \n",(err==SUCCESS)?"True":"False");
   	 printfflush();
#endif
   	 
   	 dbg("Epoch" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
   	 printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
   	 printfflush();
#endif
   	 
   	 if(!(call AggMinSendQueue.empty()))
   	 {
   		 post sendAggMinTask();
   	 }

}
}
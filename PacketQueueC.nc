#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif

generic module PacketQueueC( uint8_t queueSize)
{
	provides interface PacketQueue;
}
implementation
{
	message_t Q[queueSize];
	uint8_t head = 0;
	uint8_t tail = 0;
	uint8_t size = 0;
	
	command bool PacketQueue.empty()
	{
		return size == 0;
	}
	
	command bool PacketQueue.full()
	{
		return size == queueSize;
	}

	command uint8_t PacketQueue.size()
	{
		return size;
	}
	
	command uint8_t PacketQueue.maxSize()
	{
		return queueSize;
	}
	
	command error_t PacketQueue.enqueue(message_t newPkt)
	{
		if (call PacketQueue.full())
		{
			dbg("PacketQueueC","enqueue(): Queue is FULL!!!\n");
#ifdef PRINTFDBG_MODE
			printf("PacketQueueC:enqueue(): Queue is FULL!!!\n");
			printfflush();
#endif
			return FAIL;
		}
				
		Q[tail] = newPkt;
		tail = (tail + 1) % queueSize;
		size++;

		dbg("PacketQueueC","enqueue(): Enqueued in pos= %u \n", (tail + queueSize - 1) % queueSize);
#ifdef PRINTFDBG_MODE
		printf("PacketQueueC : enqueue() : pos=%u \n", (tail + queueSize - 1) % queueSize);
		printfflush();
#endif
		return SUCCESS;
	}
	
	command error_t PacketQueue.dequeue(message_t* m)
	{
		if (call PacketQueue.empty())
		{
			dbg("PacketQueueC","dequeue(): Q is emtpy!!!!\n");
#ifdef PRINTFDBG_MODE
			printf("PacketQueueC : dequeue() : Q is empty!!! \n");
			printfflush();
#endif
			return FAIL;
		}
		
		*m = Q[head];
		head = (head + 1) % queueSize;
		size--;

		dbg("PacketQueueC","dequeue(): Dequeued from pos = %u \n", head);
#ifdef PRINTFDBG_MODE
		printf("PacketQueueC : dequeue(): pos = %u \n", head);
		printfflush();
#endif
		return SUCCESS;
	}
	
	command message_t* PacketQueue.element(uint8_t mindex)
	{
		if (mindex >= queueSize) {
			return NULL;
		}
		return &Q[mindex];
	}

	// This is deprecated and unsafe. It should not be used.
	command message_t PacketQueue.head()
	{	
		return Q[head];
	}
}
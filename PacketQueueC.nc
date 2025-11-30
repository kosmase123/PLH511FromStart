#include "message.h"

generic module PacketQueueC(uint8_t queueSize)
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

    command message_t PacketQueue.head()
    {
        if (size > 0) {
            return Q[head];
        } else {
            message_t m;
            return m;
        }
    }
	
	command error_t PacketQueue.enqueue(message_t newVal)
	{
		if (call PacketQueue.full()) {
			return FAIL;
		}
		Q[tail] = newVal;
		tail = (tail + 1) % queueSize;
		size++;
		return SUCCESS;
	}
	
	command message_t PacketQueue.dequeue()
	{
		message_t pkt;
		if (call PacketQueue.empty()) {
			return pkt; 
		}
		pkt = Q[head];
		head = (head + 1) % queueSize;
		size--;
		return pkt;
	}
	
	command message_t PacketQueue.element(uint8_t mindex)
	{
		// This is unsafe, but matches the original implementation.
		return Q[mindex];
	}
}

#include "message.h"

generic module PacketQueueC(uint8_t queueSize)
{
	provides interface PacketQueue;
	
	message_t Q[queueSize];
	uint8_t head = 0;
	uint8_t tail = 0;
	uint8_t size = 0;
	
	implementation
	{
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
			if (call PacketQueue.full()) {
				return FAIL;
			}
			Q[tail] = newPkt;
			tail = (tail + 1) % queueSize;
			size++;
			return SUCCESS;
		}
		
		command message_t PacketQueue.dequeue()
		{
			message_t pkt;
			if (call PacketQueue.empty()) {
				// Returning an uninitialized message_t on empty queue
				// is not ideal, but it's consistent with the previous
				// implementation's behavior in error cases.
				return pkt; 
			}
			pkt = Q[head];
			head = (head + 1) % queueSize;
			size--;
			return pkt;
		}
		
		command message_t PacketQueue.elementAt(uint8_t loc)
		{
			if (loc < size) {
				return Q[(head + loc) % queueSize];
			} else {
				message_t m;
				return m;
			}
		}
	}
}
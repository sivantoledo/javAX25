import java.util.*;
import com.ae5pl.nsutil.*;

final class TNCQueue
{
	private final nsVector queue = new nsVector();
	private boolean queueEnabled = true;

	/**
	 * This gets the next object on the queue.
	 * 
	 * @return This is null if the queue is disabled.
	 */
	final synchronized TNCInterface.AX25Packet getFromQueue()
	{
		if (queueEnabled)
		{
			if (queue.isEmpty())
			{
				try {wait();} catch (InterruptedException e){}
				if (!queueEnabled)
					return null;
			}
			TNCInterface.AX25Packet retval = (TNCInterface.AX25Packet)queue.firstElement();
			queue.removeElementAt(0);
			return retval;
		}
		return null;
	}

	/**
	 * Checks for whether the queue is enabled.
	 */
	final synchronized boolean isEnabled()
	{
		return queueEnabled;
	}

	/**
	 * This puts the object on the queue.
	 * 
	 * @param newObject If this is null, the queue is purged and shut down.
	 */
	final synchronized void putOnQueue(TNCInterface.AX25Packet newObject)
	{
		if (queueEnabled)
		{
			if (newObject == null)
			{
				queue.removeAllElements();
				queueEnabled = false;
			}
			else
				queue.addElement(newObject);
			notifyAll();
		}
	}
}

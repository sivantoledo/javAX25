/*
 * Test program for the Afsk1200 sound-card modem.
 * For examples, see test.bat
 * 
 * Copyright (C) Sivan Toledo, 2012
 * 
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
package sivantoledo.ax25test;

import java.io.BufferedReader;

import gnu.io.CommPort;
import gnu.io.CommPortIdentifier;
import gnu.io.NoSuchPortException;
import gnu.io.PortInUseException;
import gnu.io.SerialPort;

import java.io.EOFException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.Properties;

import javax.sound.sampled.*;

import sivantoledo.ax25.Afsk1200Modulator;
import sivantoledo.ax25.Afsk1200MultiDemodulator;
import sivantoledo.ax25.Packet;
import sivantoledo.ax25.PacketDemodulator;
import sivantoledo.ax25.PacketHandler;
import sivantoledo.radiocontrol.SerialTransmitController;
import sivantoledo.radiocontrol.TransmitController;
import sivantoledo.sampledsound.Soundcard;

public class Test implements PacketHandler {
	
	private int packet_count;
	private long sample_count;
	private byte[] last;
	private long   last_sample_count;
	private int dup_count;
	public void incSampleCount() { sample_count++; }
	public void handlePacket(byte[] bytes) {
		System.out.println(Packet.format(bytes));
		return;
		/*
		if (last!=null && Arrays.equals(last, bytes) && sample_count <= last_sample_count + 100) {
			dup_count++;
			System.out.printf("Duplicate, %d so far\n",dup_count);
		} else {
			packet_count++;
			System.out.println(""+packet_count);
			last = bytes;
			last_sample_count = sample_count;
		}
		*/
	}
	
	
	public static void xxxptt(boolean transmit, SerialPort ptt_serial_port, String type) {
		System.out.printf("PTT %b using %s\n",transmit,type);
		if (type.equalsIgnoreCase("RTS")) {
				ptt_serial_port.setRTS(transmit);
		}
		if (type.equalsIgnoreCase("DTR")) {
			ptt_serial_port.setDTR(transmit);
		}
		/*
		String cmd = null;
		if (method.equalsIgnoreCase("Windows")) {
			cmd = String.format("cmd /C \"mode %s %s=%s\"",
					                "xxx",type,
					                transmit ? "on" : "off");
		}
		
		try { 
			Process process=Runtime.getRuntime().exec(cmd); 
			process.waitFor(); 
			BufferedReader reader=new BufferedReader(new InputStreamReader(process.getInputStream())); 
			String line=reader.readLine(); 
			while(line!=null) { 
				System.out.println("PTT control: "+line); 
		    line=reader.readLine(); 
		  } 
		} catch(IOException e1) {
			System.out.println("IO Exception trying to run PTT-related command: "+e1.getMessage()); 
		} catch(InterruptedException e2) {
			System.out.println("Interrupted Exception trying to run PTT-related command: "+e2.getMessage()); 
		} 
		*/		
	}
		
	/*
	 * main program for testing the Afsk1200 modem.
	 */
	public static void main(String[] args) {
		//for (int i=0; i<args.length; i++) {
		//	System.out.println("[[["+args[i]+"]]]");
		//}
		
		Properties p = System.getProperties();

		/*** enumerate sound devices ***/
		
		if (p.containsKey("enumerate")) {
			Soundcard.enumerate();
			System.exit(0);
		}
		
		/*** PTT ***/
		
		if (p.containsKey("serial-enumerate")) { //
			SerialTransmitController.enumerate();
			System.exit(0);
		}

		String ptt_port   = p.getProperty("ptt-port", null);
		String ptt_mode   = p.getProperty("ptt-signal", "RTS");

		TransmitController ptt = null;
		if (ptt_port != null) {
			try {
				ptt = new SerialTransmitController(ptt_port,ptt_mode);
			} catch (Exception e) {
				System.err.println("PTT initialization error: "+e.getMessage());
				System.exit(1);
			}
		} else {
			System.out.println("No PTT port");
		}
		
		/*** create an AFSK modem ***/
		
		int rate = 48000;
		int filter_length = 32;
		
		try {
			rate = Integer.parseInt(p.getProperty("rate", "48000").trim());
		} catch (Exception e){
			System.err.println("Exception parsing rate "+e.toString());
		}

		try {
			filter_length = Integer.parseInt(p.getProperty("filter-length", "32").trim());
		} catch (Exception e){
			System.err.println("Exception parsing rate "+e.toString());
		}

		Test t = new Test();
		//System.out.printf("%d %d\n",rate,filter_length);
		Afsk1200Modulator mod = null;
		//Afsk1200 afsk = null;
		//PacketDemodulator afsk0 = null;
		//PacketDemodulator afsk6 = null;
		PacketDemodulator multi = null;
		try {
		  //afsk = new Afsk1200(rate,filter_length,0,t);
		  //afsk0 = new Afsk1200Demodulator(rate,filter_length,0,t);
		  //afsk6 = new Afsk1200Demodulator(rate,filter_length,6,t);
		  multi = new Afsk1200MultiDemodulator(rate,t);
		  mod = new Afsk1200Modulator(rate);
		} catch (Exception e) {
			System.out.println("Exception trying to create an Afsk1200 object: "+e.getMessage());
			System.exit(1);
		}
		
		/*** create test packet to transmit ***/
		
	  //byte[] contents = "Test Packet Hex FF=?; Done!".getBytes();
	  //contents[19] = (byte) 0xff;
	  //Packet packet = new Packet(contents);
		String callsign = p.getProperty("callsign", "NOCALL");
	  
		System.out.println("Callsign in test packet is: "+callsign);
		
	  Packet packet = new Packet("APRS",
        callsign,
        new String[] {"WIDE1-1", "WIDE2-2"},
        Packet.AX25_CONTROL_APRS,
        Packet.AX25_PROTOCOL_NO_LAYER_3,
        ">Java Modem Test Packet".getBytes());

	  /*** loopback: testing the modem without sound ***/
	  
	  if (p.containsKey("loopback")) {
		  //ae.afsk.transmit(new Packet(contents));
	  	System.out.println("Loopback test");
		  mod.prepareToTransmit(packet);
		  float[] tx_samples = mod.getTxSamplesBuffer();
		  int n;
		  while ((n = mod.getSamples()) > 0){
		  	//System.out.printf("sending %d samples",n);
		  	//afsk.addSamples(Arrays.copyOf(tx_samples, n));
		  	multi.addSamples(tx_samples, n);
		  }
			System.exit(0);
		}
	  
		/*** write a test packet to a text file ***/

		String fout = p.getProperty("file-output", null);
		if (fout != null) {	
			System.out.printf("Writing transmit packets to <%s>\n",fout);
			FileOutputStream f = null;
			PrintStream ps = null;
			try {
				f = new FileOutputStream(fout);
				ps = new PrintStream(f);
			} catch (FileNotFoundException fnfe) {
				System.err.println("File "+fout+" not found: "+fnfe.getMessage());
				System.exit(1);
			}
		  mod.prepareToTransmit(packet);
		  int n;
		  float[] tx_samples = mod.getTxSamplesBuffer();
		  while ((n = mod.getSamples()) > 0) {
		  	for (int i=0; i<n; i++)
		  	  ps.printf("%09e\n",tx_samples[i]);
		  }
		  ps.close();
			System.exit(0);
		}
		
		/*** process an input sound file ***/

		String fin = p.getProperty("file-input", null);
		if (fin != null) {	
			System.out.printf("Trying to decode packets from <%s>\n",fin);
			AudioInputStream ios = null;
			try {
				ios = AudioSystem.getAudioInputStream(new File(fin));
			} catch (IOException ioe) {
				System.err.println("IO Error: "+ioe.getMessage());
				System.exit(1);
			} catch (UnsupportedAudioFileException usafe) {
				System.err.println("Audio file format not supported: "+usafe.getMessage());
				System.exit(1);
			}
			AudioFormat fmt = ios.getFormat();
			System.out.printf("Audio rate is %d, %d channels, %d bytes per frame, %d bits per sample\n",
					(int) fmt.getSampleRate(),
					fmt.getChannels(),
					fmt.getFrameSize(),
					fmt.getSampleSizeInBits());
			
			int decimation = 1;
			double d = fmt.getSampleRate() / rate;
			if (Math.abs(Math.round(d)-d) / d < 0.01) decimation = (int) Math.round(d);
			else {
				System.err.printf("Sample rates must match or lead to decimation by an integer!\n");
				System.exit(1);				
			} 
			
			byte[] raw = new byte[fmt.getFrameSize()];
			float[] f = new float[1];
			ByteBuffer bb;
			if (fmt.isBigEndian())
		    bb = ByteBuffer.wrap(raw).order(ByteOrder.BIG_ENDIAN);
			else
		    bb = ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN);
			int j = 0;
			int k = 0;
			float scale = 0.0f;
			switch (fmt.getSampleSizeInBits()){
			case 32: scale = 1.0f / ((float) fmt.getChannels() * 2147483648.0f ); break;
			case 16: scale = 1.0f / ((float) fmt.getChannels() *      32768.0f ); break;
			case  8: scale = 1.0f / ((float) fmt.getChannels() *        256.0f ); break;
			}
			//System.out.printf("Format bits per sample = %d\n",fmt.getSampleSizeInBits());
			while (true) {
				try {
					int n = ios.read(raw);
					if (n != raw.length) {
						System.err.printf("Done!?!\n");
						System.exit(1);										
					}
					bb.rewind();
					f[0] = 0.0f;
					// we average over channels (stereo)
					for (int i=0; i<fmt.getChannels(); i++) {
						switch (fmt.getSampleSizeInBits()){
						case 32: f[0] += (float) bb.getInt();   break;
						case 16: f[0] += (float) bb.getShort(); break;
						case  8: f[0] += (float) bb.get();      break;
						default:
							System.err.printf("Can't process files with %d bits per sample\n",fmt.getSampleSizeInBits());
							System.exit(1);
						}
					}
					f[0] = scale*f[0];
					if (j==0) {
						t.incSampleCount();
						//afsk.addSamples(f, 1);
						//afsk0.addSamples(f, 1);
						//afsk6.addSamples(f, 1);
						//if (f[0] > 32768.0f || f[0] < -32768.0f) System.out.printf("Weird short sample value %f\n", f[0]);
						multi.addSamples(f, 1);
						
						k++;
						if (k==rate) {
							System.out.printf("peak level %d\n",multi.peak());
							k=0;
						}
					}
					j++;
					if (j==decimation) j=0;
				} catch (EOFException eofe) {
					System.out.println("Done!");
				} catch (IOException e) {
					System.err.println("IO Error while reading audio: "+e.getMessage());
				}
			}
		}
		
	  /*** preparing to generate or capture audio packets ***/
			  
		String input = p.getProperty("input", null);
		String output = p.getProperty("output", null);

		int buffer_size = -1;
		try {
			// our default is 100ms
			buffer_size = Integer.parseInt(p.getProperty("latency", "100").trim());
			//if (buffer_size ==-1) buffer_size = sc.rate/10;
			//ae.capture_buffer = new byte[2*buffer_size];
		} catch (Exception e){
			System.err.println("Exception parsing buffersize "+e.toString());
		}
		
		Soundcard sc = new Soundcard(rate,input,output,buffer_size,multi,mod);

		if (p.containsKey("audio-level")) {
			sc.displayAudioLevel();
		}

		/*** generate test tones and exit ***/

		int tones_duration = -1; // in seconds
		try {
			tones_duration = Integer.parseInt(p.getProperty("tones", "-1").trim());
		} catch (Exception e){
			System.err.println("Exception parsing tones "+e.toString());
		}
		if (tones_duration > 0) {
  		//sc.openSoundOutput(output);			
		  mod.prepareToTransmitFlags(tones_duration);
			if (ptt != null) ptt.startTransmitter();
		  sc.transmit();
			if (ptt != null) ptt.stopTransmitter();
			if (ptt != null) ptt.close();
			System.exit(0);
		}

		/*** sound a test packet and exit ***/

		if (output != null) {
  		//sc.openSoundOutput(output);			
		  mod.prepareToTransmit(packet);
		  System.out.printf("Start transmitter\n");
		  //sc.startTransmitter();
			if (ptt != null) ptt.startTransmitter();
		  sc.transmit();
		  System.out.printf("Stop transmitter\n");
			if (ptt != null) ptt.stopTransmitter();
			if (ptt != null) ptt.close();
			//if (ptt != null) ptt.stopTransmitter());
		  //sc.stopTransmitter();
		  //int n;
		  //while ((n = ae.afsk.getSamples()) > 0){
		 // 	ae.afsk.addSamples(Arrays.copyOf(tx_samples, n));
		  //}
			System.exit(0);
		}
		
		/*** listen for incoming packets ***/

		if (input != null) {
		  System.out.printf("Listening for packets\n");
  		//sc.openSoundInput(input);			
	    sc.receive();
		}
	  
		//ae.run(afsk);
	}

}

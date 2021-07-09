import com.dosse.openldat.device.Device;
import com.dosse.openldat.device.DeviceFinder;
import com.dosse.openldat.device.callbacks.LightSensorMonitorCallback;
import com.dosse.openldat.processing.buffers.CircularBuffer;
import com.dosse.openldat.processing.filters.FFTFilter;
import com.dosse.openldat.processing.filters.PeakHoldFilter;
import com.dosse.openldat.processing.filters.RunningAverageSmoothingFilter;

public class FiltersExample {

	public static void main(String[] args) {
		//ottieni il primo device OpenLDAT disponibile
		Device d = DeviceFinder.getDevice();
		//inizializza un buffer in cui memorizzare il segnale originale
		CircularBuffer originalSignal=new CircularBuffer(8192);
		//inizializza dei filtri con cui processare il segnale (in questo caso, lo processiamo mentre lo catturiamo, ma possiamo anche farlo dopo)
		FFTFilter fft=new FFTFilter(8192);
		RunningAverageSmoothingFilter smooth=new RunningAverageSmoothingFilter(8192,0.99);
		PeakHoldFilter peakHold=new PeakHoldFilter(8192,64);
		//avvia il campionamento (memorizziamo il sample rate per poter calcolare le frequenze dei bin dell'FFT dopo)
		double sampleRate=0;
		try {
			sampleRate=d.lightSensorMonitorMode(true, (byte)3, false, new LightSensorMonitorCallback(){
				@Override
				public void onDataSampleReceived(int data) {
					//aggiungi ogni sample ricevuto al buffer e ai 3 filtri
					originalSignal.add(data);
					fft.add(data);
					smooth.add(data);
					peakHold.add(data);
				}
			});
		} catch (Exception e) {
			System.out.println("Si è verificato un errore");
			System.exit(2);
		}
		//campionamento avviato, attendi che il buffer sia pieno
		while(!originalSignal.isFilled()){try{Thread.sleep(1);}catch(Throwable t){}}
		//interrompi il campionamento
		d.endCurrentActivity();
		//stampa il segnale e l'output dei filtri
		System.out.println("Segnale originale:");
		int[] data=originalSignal.getData();
		for(int i=0;i<data.length;i++){
			System.out.println(i+"\t"+data[i]);
		}
		System.out.println("\n");
		System.out.println("FFTFilter:");
		data=fft.getData();
		for(int i=0;i<data.length;i++){
			double freq=((double)i/(double)fft.getSize())*(sampleRate/2.0);
			System.out.println(String.format("%.2f", freq)+"\t"+data[i]);
		}
		System.out.println("\n");
		System.out.println("RunningAverageSmoothingFilter:");
		data=smooth.getData();
		for(int i=0;i<data.length;i++){
			System.out.println(i+"\t"+data[i]);
		}
		System.out.println("\n");
		System.out.println("PeakHoldFilter:");
		data=peakHold.getData();
		for(int i=0;i<data.length;i++){
			System.out.println(i+"\t"+data[i]);
		}
		System.out.println("\n");
		//chiudi il dispositivo e termina il programma
		d.close();
		System.exit(0);
	}
}

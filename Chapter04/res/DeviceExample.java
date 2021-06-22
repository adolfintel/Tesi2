import com.dosse.openldat.device.Device;
import com.dosse.openldat.device.DeviceFinder;
import com.dosse.openldat.device.callbacks.LightSensorButtonCallback;
import com.dosse.openldat.device.errors.MissingSensorException;
import java.io.IOException;

public class DeviceExample {

	public static void main(String[] args) {
		//ottieni il primo device OpenLDAT disponibile
		Device d = DeviceFinder.getDevice();
		if (d == null) {
			System.out.println("Nessun dispositivo OpenLDAT trovato");
			System.exit(1);
		}
		//avvia il campionamento
		boolean noBuffer = true, fastADC = true, autoFire = true;
		try {
			d.lightSensorButtonMode(noBuffer, (byte) 2, fastADC, true, autoFire, new LightSensorButtonCallback() {
				@Override
				public void onDataBufferReceived(int[] light, int[] click) { //viene chiamato solo se noBuffer=false
					System.out.println("Ricevuto un nuovo buffer");
					for (int i = 0; i < light.length; i++) {
						System.out.println("Light:" + light[i] + ", Button:" + click[i]);
					}
				}

				@Override
				public void onDataSampleReceived(int light, int click) { //viene chiamato solo se noBuffer=true
					System.out.println("Ricevuto un nuovo sample");
					System.out.println("Light:" + light + ", Button:" + click);
				}

				@Override
				public void onError(Exception e) {
					System.out.println("Si è verificato un errore di comunicazione");
				}
			});
		} catch (MissingSensorException e) {
			System.out.println("Il dispositivo non ha un sensore di luminosità");
			System.exit(2);
		} catch (IOException e) {
			System.out.println("Non è stato possibile inviare il comando al dispositivo");
			System.exit(3);
		}
		//campionamento avviato, continua per 10 secondi
		try {Thread.sleep(10000);} catch (InterruptedException ex) {}
		//interrompi il campionamento
		d.endCurrentActivity();
		System.out.println("Interrotto dopo 10 secondi");
		//chiudi il dispositivo e termina il programma
		d.close();
		System.exit(0);
	}
}


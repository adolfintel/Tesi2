import com.dosse.openldat.Config;
import com.dosse.openldat.Utils;
import com.dosse.openldat.device.Device;
import com.dosse.openldat.tests.ITest;
import com.dosse.openldat.tests.IgnorableException;
import com.dosse.openldat.tests.TestException;
import com.dosse.openldat.tests.testscreen.ITestScreen;
import com.dosse.openldat.tests.testscreen.opengl.TestScreenGL;
import com.dosse.openldat.tests.testscreen.swing.TestScreenSwing;
import java.util.HashMap;

public abstract class TestExample extends Thread implements ITest {

    private final Device d;
    private final ITestScreen ts;
    private boolean enterPressed, escPressed, stopASAP = false;
    private int durationMs;
    private static final boolean unbuffered = false, fastADC = true;
    private static final int vsyncMode=TestScreenGL.VSYNC_ON;

    public TestExample(Device d) {
        //Inizializza il backend grafico
        this.d = d;
        if (Config.TESTSCREEN_GL) {
            ts = new TestScreenGL(vsyncMode) {
                @Override
                public void onEnterPressed() { //tasto invio premuto, aggiorna la variabile
                    enterPressed = true;
                }
                @Override
                public void onCancel() { //tasto esc premuto, aggiorna la variabile
                    escPressed = true;
                    InputLagTest.this.interrupt();
                }
                @Override
                public void onError(Exception e) { //errore del backend grafico
                    if (stopASAP) return;
                    stopASAP = true;
                    InputLagTest.this.interrupt();
                    InputLagTest.this.onError(e);
                }
            };
        } else {
            ts = new TestScreenSwing() {
                @Override
                public void onEnterPressed() { //tasto invio premuto, aggiorna la variabile
                    enterPressed = true;
                }
                @Override
                public void onCancel() { //tasto esc premuto, aggiorna la variabile
                    escPressed = true;
                    InputLagTest.this.interrupt();
                }
                @Override
                public void onError(Exception e) { //errore del backend grafico
                    if (stopASAP) return;
                    stopASAP = true;
                    InputLagTest.this.interrupt();
                    InputLagTest.this.onError(e);
                }
            };
        }
    }
    @Override
    public void run() {
        try {
            //Imposta lo sfondo nero col target bianco al centro
            ts.setColor(0, 0, 0);
            ts.setTarget(0.5f, 0.5f, 0.2f, false);
            //Attendi la pressione del tasto invio. Se il test viene annullato, gestisci l'evento. Il seguente blocco può essere copiato in diversi punti del test in cui è sicuro interromperlo.
            while (!(enterPressed || escPressed || stopASAP)) Utils.sleep(10);
            if (stopASAP) { //annullato tramite onCancel o errore del backend grafico (che chiama già onError, non lo facciamo di nuovo)
                ts.close();
                return;
            }
            if (escPressed) { //annullato tramite il tasto Esc
                ts.close();
                onError(new TestException(TestException.USER_ABORT));
                return;
            }
            enterPressed = false; //Il tasto invio è stato premuto, prepararsi alla prossima pressione
            ts.hideTarget(); //Rimuovi il target
            HashMap<String, Object> ret = new HashMap<>(); //Inizializza il Map da ritornare a fine test
            
            /**
            * INSERIRE IL CODICE DEL TEST QUÌ
            * I risultati del test devono essere inseriti in ret
            */
            
            //Fine del test, chiama il relativo callback
            onDone(ret);
        } catch (Exception ex) {
            //Test interrotto. Interrompi eventuali catture dal dispositivo e chiama il relativo callback
            try {
                d.endCurrentActivity();
            } catch (Throwable t) {}
            ts.close();
            if (!(ex instanceof IgnorableException)) onError(ex);
        }
    }
    @Override
    public void begin() {
        start();
    }
    @Override
    public void cancel() {
        stopASAP = true;
        this.interrupt();
    }
}
 

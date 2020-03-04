package code;

import java.awt.EventQueue;

import javax.swing.JFrame;
import javax.swing.JPanel;


public class Game_JFrame extends JFrame {

	private static final long serialVersionUID = 1L;

	private JPanel panel;
	
	public static void main(String[] args) {
		
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					Game_JFrame frame = new Game_JFrame(new Game_GUI());
					frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}
	
	
	
	
	public Game_JFrame(Game_GUI sketch) {
		setResizable(false);
		setTitle("Flappy Bird");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setVisible(true);
		setLocation(10, 10);
		setSize(470, 600);
		getContentPane().setLayout(null);
		
		panel = new JPanel(null);
		panel.setBounds(10, 11, 564, 539);
		//panel.setBackground(Color.WHITE);
		panel.add(sketch);
		sketch.init();
		
		getContentPane().add(panel);
		
	}
}
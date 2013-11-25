require "hacky_hal"
require "yaml"

class Remote
  DEVICE_FILE = "./devices.yml"

  def initialize
    define_device_methods
  end

  def set_input_output(options)
    avr_input = options["av_receiver_input"]
    avr_output = options["av_receiver_output"].split(",")
    switch_input = options["secondary_monitor_switch_input"].to_i

    avr_projector_output = avr_output.include?(projector[:av_receiver_output])
    avr_monitor_output = avr_output.include?(primary_monitor[:av_receiver_output])

    setup_av_reciever(avr_input)
    av_receiver.set_hdmi_output("OUT_1", avr_projector_output)
    av_receiver.set_hdmi_output("OUT_2", avr_monitor_output)

    secondary_monitor_switch.input = switch_input

    set_laptop_audio_output(avr_input, avr_projector_output)
    set_laptop_mirroring(avr_input, switch_input)

    set_pc_mirroring(avr_input, switch_input)
    reset_pc_screens
  end

  def toggle_av_receiver_power
    HackyHAL::Log.instance.debug(av_receiver.on)
    av_receiver.on = !av_receiver.on
  end

  def toggle_projector_power
    projector.on = !projector.on
  end

  def increase_volume(options)
    av_receiver.volume += options["amount"].to_i || 1
  end

  def mute
    av_receiver.mute = !av_receiver.mute
  end

  def rain
    rain_off
    laptop.exec("open /Applications/SimplyRain.app")
    set_laptop_audio_output_device("RX-A1020 90E681")
    disable_avr_output
    disable_secondary_screen
    av_receiver.volume = -45.0
    projector.on = false
  end

  def rain_off
    laptop.exec('pkill -9 -f ".*SimplyRain.*"')
  end

  def all_off
    disable_avr_output
    av_receiver.on = false
    disable_secondary_screen
    projector.on = false
  end

  def laptop_on_projector
    set_input_output(
      "av_receiver_input" => laptop[:av_receiver_input],
      "av_receiver_output" => projector[:av_receiver_output],
      "secondary_monitor_switch_input" => secondary_monitor_switch[:unused_input]
    )
  end

  def laptop_on_both_monitors
    set_input_output(
      "av_receiver_input" => laptop[:av_receiver_input],
      "av_receiver_output" => primary_monitor[:av_receiver_output],
      "secondary_monitor_switch_input" => laptop[:secondary_monitor_switch_input]
    )
  end

  def pc_on_projector
    projector.on = true
    set_input_output(
      "av_receiver_input" => pc[:av_receiver_input],
      "av_receiver_output" => projector[:av_receiver_output],
      "secondary_monitor_switch_input" => secondary_monitor_switch[:unused_input]
    )
  end

  def pc_on_both_monitors
    set_input_output(
      "av_receiver_input" => pc[:av_receiver_input],
      "av_receiver_output" => primary_monitor[:av_receiver_output],
      "secondary_monitor_switch_input" => pc[:secondary_monitor_switch_input]
    )
  end

  def ps3_on_projector
    projector.on = true
    set_input_output(
      "av_receiver_input" => ps3[:av_receiver_input],
      "av_receiver_output" => projector[:av_receiver_output],
      "secondary_monitor_switch_input" => secondary_monitor_switch[:unused_input]
    )
  end

  def roku_on_projector
    projector.on = true
    set_input_output(
      "av_receiver_input" => roku[:av_receiver_input],
      "av_receiver_output" => projector[:av_receiver_output],
      "secondary_monitor_switch_input" => secondary_monitor_switch[:unused_input]
    )
  end

  def disable_secondary_screen
    secondary_monitor_switch.input = secondary_monitor_switch[:unused_input]
  end

  def netflix
    open_roku_app("Netflix")
  end

  def amazon_video
    open_roku_app("Amazon Instant Video")
  end

  def set_laptop_audio_output_device(name)
    laptop.set_audio_output_device(name)
  end

  # def disconnect
    # projector.disconnect
    # laptop.disconnect
    # pc.disconnect
  # end

  # def projector_lamp_hours
    # projector.lamp_hours
  # end

  private

  def devices
    HackyHAL::Registry.instance.devices
  end

  def define_device_methods
    registry = HackyHAL::Registry.instance
    registry.load_yaml_file(DEVICE_FILE)

    registry.devices.each_pair do |device_name, device|
      define_singleton_method device_name do
        device
      end
    end
  end

  def setup_av_reciever(input = AV_RECEIVER_DEFAULT_INPUT)
    av_receiver.input = input
    av_receiver.on = true
    av_receiver.mute = false
    # av_receiver.volume = -30.0
  end

  def disable_avr_output
    av_receiver.set_hdmi_output("OUT_1", false)
    av_receiver.set_hdmi_output("OUT_2", false)
  end

  def mirror_pc_screens
    pc.mirror_screens("HDMI-0", "DVI-D-0")
  end

  def unmirror_pc_screens
    pc.set_screen_position("DVI-D-0", "HDMI-0", :left)
  end

  # This fixes causes the PC to output with the correct display settings when
  # switching from the monitor to the projector
  def reset_pc_screens
    pc.reset_display_settings("HDMI-0")
  end

  def mirror_laptop_screens
    laptop.mirror_screens
  end

  def unmirror_laptop_screens
    laptop.unmirror_screens
  end

  def set_laptop_mirroring(avr_input, switch_input)
    if avr_input == laptop[:av_receiver_input] &&
        switch_input == laptop[:secondary_monitor_switch_input]
      unmirror_laptop_screens
    else
      mirror_laptop_screens
    end
  end

  def set_pc_mirroring(avr_input, switch_input)
    if avr_input == pc[:av_receiver_input] &&
        switch_input == pc[:secondary_monitor_switch_input]
      unmirror_pc_screens
    else
      mirror_pc_screens
    end
  end

  def set_laptop_audio_output(avr_input, avr_projector_output)
    # TODO: Possibly clean this up by getting the list of available audio
    # outputs
    if avr_input == laptop[:av_receiver_input]
      if avr_projector_output
        set_laptop_audio_output_device("EPSON PJ")
      else
        set_laptop_audio_output_device("DELL 2408WFP")
      end
    else
      set_laptop_audio_output_device("Internal Speakers")
    end
  end
end

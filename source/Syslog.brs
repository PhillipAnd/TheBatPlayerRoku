Function GetSyslog() as Object
  if GetGlobalAA().DoesExist("SyslogService")
    return GetGlobalAA().SyslogService
  end if

  this = {
    udp: invalid
    send: _sendSyslogMessage
    deviceId: createobject("roDeviceInfo").GetDeviceUniqueId()
  }

  udp = createobject("roDatagramSocket")
  udp.setMessagePort(GetPort())

  addr = createobject("roSocketAddress")
  addr.SetHostName(GetConfig().SyslogServer)
  addr.setPort(GetConfig().SyslogPort)
  udp.setAddress(addr)
  udp.setSendToAddress(addr)
  udp.notifyReadable(true)
  this.udp = udp
  GetGlobalAA().SyslogService = this

  return this
End Function

Function _sendSyslogMessage(message, level = 6)
    logLevel = level + 1*8
    message = "<" + ToStr(logLevel) + ">" + m.deviceId + ":" + message
    m.udp.sendStr(message)
End Function

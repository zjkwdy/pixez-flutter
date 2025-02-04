#pragma once

#include <thread>

#include <flutter/flutter_engine.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

class SingleInstance
{
private:
  static LPCTSTR name;
  static LPCTSTR pipePrefix;

  static void sentEvent(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&event);
  static std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> onListen(
      const flutter::EncodableValue *args,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&event);
  static std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> onCancel(
      const flutter::EncodableValue *args);

public:
  static void Initialize(flutter::FlutterEngine *engine);
  static HANDLE SetMutex();
};

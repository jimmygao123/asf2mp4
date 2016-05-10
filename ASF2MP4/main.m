//
//  main.m
//  ASF2MP4
//
//  Created by jimmygao on 3/23/16.
//  Copyright (c) 2016 jimmygao. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/avstring.h>
#include <libavutil/error.h>
#include <libavutil/dict.h>
#include <libavformat/avio.h>
#include <libavutil/log.h>

static void log_callback(void* x, int level, const char* fmt, va_list ap)
{
    if(level == AV_LOG_FATAL){
        printf("ffmpeg_fatal:");
        vprintf(fmt,ap);
    }else if(level == AV_LOG_ERROR){
        printf("ffmpeg_error:");
        vprintf(fmt, ap);
    }else if(level == AV_LOG_WARNING){
        printf("ffmpeg_warning:");
        vprintf(fmt, ap);
    }
}

int recordConvert(const char * filepath, const char *outputpath);
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *documentPath = (NSString *)[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *inputFile = [documentPath stringByAppendingPathComponent:@"a.asf"];
        NSString *outputFile = [documentPath stringByAppendingPathComponent:@"b.mp4"];
        NSLog(@"asf: filePath = %@,mp4: filePath = %@",inputFile,outputFile);
        
        av_register_all();
        av_log_set_callback(log_callback);
        recordConvert(inputFile.UTF8String, outputFile.UTF8String);
        

//        AVFormatContext *iFmtCtx = NULL;
//        AVFormatContext *oFmtCtx = NULL;
//        
//        AVCodecContext *encCtx = NULL;
//        AVCodecContext *decCtx = NULL;
//        
//        //1.input
//        if(avformat_open_input(&iFmtCtx, inputFile.UTF8String, NULL, NULL) < 0){
//            av_log(NULL, AV_LOG_ERROR, "Cannot open the input file:%s",inputFile.UTF8String);
//            return -1;
//        }
//        
//        if(avformat_find_stream_info(iFmtCtx, 0)<0){
//            av_log(NULL, AV_LOG_ERROR, "Cannot file the streams in input file:%s",inputFile.UTF8String);
//            return -1;
//        }
//        
//        av_dump_format(iFmtCtx, 0, inputFile.UTF8String, 0);
//        av_dump_format(iFmtCtx, 1, inputFile.UTF8String, 0);
//        
//        //2.output
//        
//        AVOutputFormat *o_format = NULL;
//        if ((o_format = av_guess_format("mp4", outputFile.UTF8String, "video/mp4")) == NULL) {
//            av_log(NULL, AV_LOG_ERROR,"can't guess the format of output file2:%s",outputFile.UTF8String);
//            return -1;
//        }
//        AVFormatContext *o_context = NULL;
//        avformat_alloc_output_context2(&o_context, o_format, NULL, NULL);
//        if (o_context == NULL) {
//            av_log(NULL,AV_LOG_ERROR, "avformat_alloc_output_context2:%s",outputFile.UTF8String);
//            return -1;
//        }
//        
//        int i = 0;
//        for(i = 0;i< iFmtCtx->nb_streams; i++){
//            AVStream *out_stream = NULL;
//            AVStream *in_stream = NULL;
//            
//            in_stream = iFmtCtx->streams[i];
//            out_stream = avformat_new_stream(oFmtCtx, in_stream->codec->codec);
//            
//            if(out_stream < 0){
//                av_log(NULL,AV_LOG_ERROR,"Alloc new stream error");
//                return -1;
//            }
//            
//            avcodec_copy_context(oFmtCtx->streams[i]->codec, iFmtCtx->streams[i]->codec);
//            
//            out_stream->codec->codec_tag = 0;
//            if(oFmtCtx->oformat->flags & AVFMT_GLOBALHEADER){
//                out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
//            }
//        }
//        
//        av_dump_format(oFmtCtx, 0,outputFile.UTF8String, 1);
        
    }
    return 0;
}
int recordConvert(const char * filepath, const char *outputpath)
{
    
    if(filepath != NULL && strlen(filepath) > 4)
    {
        NSLog(@"asf path = %s,mp4 path = %s\n",filepath,outputpath);
        AVFormatContext * outputContext = avformat_alloc_context();
        AVOutputFormat * outputFormat = av_guess_format(NULL, outputpath, NULL);
        
        if(outputFormat == NULL)
        {
            NSLog(@"error,%s:av_guess_format error %s\n",__FUNCTION__,outputpath);
            return -1;
        }
        outputContext->oformat = outputFormat;
        
        av_strlcpy(outputContext->filename, outputpath, sizeof(outputContext->filename));
        outputContext->nb_streams = 0;
        
        AVStream * outvideostream =  avformat_new_stream(outputContext, NULL);
        AVStream * outaudiostream = avformat_new_stream(outputContext, NULL);
        
        AVFormatContext * pFormatCtx = NULL;
        int ret = avformat_open_input(&pFormatCtx,filepath,NULL,NULL);
        if(ret < 0)
        {
            NSLog(@"error %s:avformat_open_input failed! %s\n",__FUNCTION__,filepath);
            return -1;
        }
        if(avformat_find_stream_info(pFormatCtx,NULL) < 0)
        {
            av_dump_format(pFormatCtx, 0, pFormatCtx->filename, 0);
            avformat_close_input(&pFormatCtx);
            NSLog(@"error %s:avfind_stream_info failed! %s\n",__FUNCTION__,filepath);
            return -2;
        }
        int video_stream_index = -1;
        int audio_stream_index = -1;
        for(int i =0 ;i<(pFormatCtx->nb_streams) ;i++)
        {
            AVStream * stream = pFormatCtx->streams[i];
            AVCodecContext * pCodecCtx = stream->codec;
            AVCodec  *pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
            if(pCodec == NULL)
            {
                NSLog(@"error %s:can't find decoder!\n%s",__FUNCTION__,filepath);
                return -1;
            }
            enum AVMediaType  type = pCodecCtx->codec_type;
            if(type == AVMEDIA_TYPE_VIDEO)
            {
                video_stream_index = i;
                
                AVCodecContext *c = outvideostream->codec;
                outputContext->video_codec_id = stream->codec->codec_id;
                outvideostream->start_time = stream->start_time;
                outvideostream->time_base.den = stream->time_base.den;
                outvideostream->time_base.num = stream->time_base.num;
                c->width = stream->codec->width;
                c->height = stream->codec->height;
                c->bits_per_raw_sample = stream->codec->bits_per_raw_sample;
                c->chroma_sample_location = stream->codec->chroma_sample_location;
                c->codec_id = stream->codec->codec_id;
                c->codec_type = stream->codec->codec_type;
                
                c->bit_rate = stream->codec->bit_rate;
                c->rc_max_rate    = stream->codec->rc_max_rate;
                c->rc_buffer_size = stream->codec->rc_buffer_size;
                
                uint64_t extra_size = (uint64_t)stream->codec->extradata_size;
                c->extradata = (uint8_t *)av_mallocz((int)extra_size);
                memcpy(c->extradata, stream->codec->extradata, stream->codec->extradata_size);
                c->extradata_size= stream->codec->extradata_size;
                
                
                c->pix_fmt = stream->codec->pix_fmt;
                c->has_b_frames = stream->codec->has_b_frames;
                c->time_base.den = stream->time_base.den;
                c->time_base.num = stream->time_base.num;
                c->gop_size = stream->codec->gop_size;
                outputFormat->video_codec = stream->codec->codec_id;
                c->flags |= CODEC_FLAG_GLOBAL_HEADER;
                
                NSLog(@"record set video stream ok!");
            }
            
            if(type == AVMEDIA_TYPE_AUDIO)
            {
                audio_stream_index = i;
                AVCodecContext *c = outaudiostream->codec;
                outputContext->audio_codec_id = stream->codec->codec_id;
                outaudiostream->start_time = 0;
                outaudiostream->time_base= (AVRational){1,1000};
                c->bits_per_raw_sample = stream->codec->bits_per_raw_sample;
                c->chroma_sample_location = stream->codec->chroma_sample_location;
                c->codec_id = stream->codec->codec_id;
                c->codec_type = stream->codec->codec_type;
                
                c->bit_rate = stream->codec->bit_rate;
                c->rc_max_rate    = stream->codec->rc_max_rate;
                c->rc_buffer_size = stream->codec->rc_buffer_size;
                c->time_base = (AVRational){1,1000};

                c->channel_layout =  stream->codec->channel_layout;
                c->sample_rate = stream->codec->sample_rate;
                c->channels = stream->codec->channels;
                c->frame_size = stream->codec->frame_size;
                c->block_align= stream->codec->block_align;
                /* put sample parameters */
                c->sample_fmt = stream->codec->sample_fmt;
                outputFormat->audio_codec = stream->codec->codec_id;
                
//                uint64_t extra_size = (uint64_t)stream->codec->extradata_size;
//                c->extradata = (uint8_t *)av_mallocz((int)extra_size);
//                memcpy(c->extradata, stream->codec->extradata, stream->codec->extradata_size);
//                c->extradata_size= stream->codec->extradata_size;
                static uint8_t extradata[] = { 0x09,0x90};
                c->extradata = extradata;
                c->extradata_size = 2;
                
                c->flags |= CODEC_FLAG_GLOBAL_HEADER;
                
                NSLog(@"record set audio stream ok!");
            }
        }
        av_dump_format(pFormatCtx, 0, filepath, 0);
        av_dump_format(outputContext, 0, outputpath, 1);
//        outputContext->max_delay = (int)(0.7*AV_TIME_BASE);
        int err = -1;
        if ((err = avio_open(&outputContext->pb, outputpath, AVIO_FLAG_WRITE)) < 0)
        {
            avformat_close_input(&pFormatCtx);
            NSLog(@"error %s:url_fopen failed %s\n", __FUNCTION__,outputpath);
            return -2;
        }
        
        if (avformat_write_header(outputContext,NULL) < 0) {
            av_free(outvideostream);
            av_free(outaudiostream);
            avformat_close_input(&pFormatCtx);
            av_free(outputContext);
            NSLog(@"error %s:av_write_header error %s\n",__FUNCTION__,outputpath);
            return -2;
        }
        
        AVRational input_base;
        input_base.num = 1;
        input_base.den =1000;
        AVPacket packet;
        int64_t starttime = -1;
        
        bool foundKframe = false;
        bool foundAudio = false;
        
        for(;;)
        {
            av_init_packet(&packet);
            packet.data = NULL;
            packet.size = 0;
            int ret = av_read_frame(pFormatCtx,&packet);
            if(ret >= 0)
                
            {
                //printf("frame index = %d  frame flag = %d timestamp = %lld\n ",packet.stream_index,packet.flags,packet.dts);
                
                if(foundAudio == false && packet.stream_index == 1)
                {
                    foundAudio = true;
                }
                
                if (foundKframe == false && packet.flags != 0 && packet.stream_index == 0 && foundAudio == true)
                {
                    foundKframe = true;
                    starttime = packet.dts;
                }
                
                
                if(foundKframe == true &&  foundAudio == true)
                {
                    packet.dts = packet.dts - starttime;
                    packet.pts = packet.dts;
                    
                    if(packet.stream_index == 1)
                    {
                        packet.dts = av_rescale_q(packet.dts, input_base, outaudiostream->codec->time_base);
                        packet.pts = packet.dts;
                        packet.duration = 1024;
                    }
                    else
                    {
                        if(packet.dts != AV_NOPTS_VALUE)
                            packet.dts = av_rescale_q(packet.dts, input_base, outvideostream->time_base);
                        if(packet.pts != AV_NOPTS_VALUE)
                            packet.pts =  packet.dts;
                    }
                    av_write_frame(outputContext, &packet);
                }
                av_free_packet(&packet);
                
            }
            else
            {
                if (ret == AVERROR_EOF || avio_feof(pFormatCtx->pb))
                    break;
            }
            
        }
        av_write_trailer(outputContext);
        av_free(outvideostream);
        av_free(outaudiostream);
        av_free(outputContext);
        avformat_close_input(&pFormatCtx);
        
    }
    return 0;
}



// -----------------------------------------------------------------------------
//  VisualSubSync
// -----------------------------------------------------------------------------
//  Copyright (C) 2003 Christophe Paris
// -----------------------------------------------------------------------------
//  This Program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2, or (at your option)
//  any later version.
//
//  This Program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with GNU Make; see the file COPYING.  If not, write to
//  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
//  http://www.gnu.org/copyleft/gpl.html
// -----------------------------------------------------------------------------

#include <windows.h>
#include <commdlg.h>
#include <streams.h>
#include <initguid.h>

#include <stdio.h>

#include "CircBuff.h"
#include "WAVFile.h"
#include "IWavWriter.h"
#include "WavWriterUIDs.h"
#include "WavWriter.h"


// Setup data

const AMOVIESETUP_MEDIATYPE sudPinTypes =
{
    &MEDIATYPE_Audio,          // Major type
    &MEDIASUBTYPE_PCM          // Minor type
};

const AMOVIESETUP_PIN sudPins =
{
    L"Input",                   // Pin string name
    FALSE,                      // Is it rendered
    FALSE,                      // Is it an output
    FALSE,                      // Allowed none
    FALSE,                      // Likewise many
    &CLSID_NULL,                // Connects to filter
    L"Output",                  // Connects to pin
    1,                          // Number of types
    &sudPinTypes                // Pin information
};

const AMOVIESETUP_FILTER sudWavWriter =
{
    &CLSID_WavWriter,           // Filter CLSID
    L"WAV Writer",               // String name
    MERIT_DO_NOT_USE,           // Filter merit
    1,                          // Number pins
    &sudPins                    // Pin details
};


//
//  Object creation stuff
//
CFactoryTemplate g_Templates[]= {
    L"WAV Writer", &CLSID_WavWriter, CWavWriterFilter::CreateInstance, NULL, &sudWavWriter
};
int g_cTemplates = 1;


void DebugLog(char *pFormat,...)
{
    char szMsg[2000];
    va_list va;		
    va_start(va, pFormat);
    wvsprintf(szMsg, pFormat, va);
    lstrcat(szMsg, TEXT("\r\n"));
	OutputDebugString(szMsg);
	va_end(va);
}

//-----------------------------------------------------------------------------

CUnknown * WINAPI CWavWriterFilter::CreateInstance(LPUNKNOWN punk, HRESULT *phr)
{
    ASSERT(phr);
    
    CWavWriterFilter *pNewObject = new CWavWriterFilter(punk, phr);
    if (pNewObject == NULL) {
        if (phr)
            *phr = E_OUTOFMEMORY;
    }
	
    return pNewObject;	
}

//-----------------------------------------------------------------------------

CWavWriterFilter::CWavWriterFilter(LPUNKNOWN pUnk, HRESULT *phr) :
    CBaseFilter(NAME("CWavWriterFilter"), pUnk, &m_Lock, CLSID_WavWriter),
	m_pPin(NULL),
	m_pFileName(0),
	m_Writting(false),
	m_dwSeekingCaps(AM_SEEKING_CanGetDuration | AM_SEEKING_CanGetCurrentPos),
	m_rtDuration(0),
	m_cbWavData(0),
	m_WavFile(NULL),
	m_bFastConvertMode(false),
	m_OutBuffSize(0),
	m_OutBuff(NULL),
	m_bWritePeakFile(false),
	m_pPeakFileName(0),
	m_PeakFile(NULL),
	m_PeakCircBuffer(NULL),
	m_PeakCalcBuffer(NULL),
	m_InputAllocatorBuffSize(0),
	m_bWriteWavFile(true),
	m_ConvCircBuffer(NULL),
	m_ConvBuffSize(0),
	m_ConvBuff(NULL)
{
	m_pPin = new CWavWriterInputPin(this, &m_Lock, &m_ReceiveLock, phr);
	if (m_pPin == NULL) {
		if (phr)
			*phr = E_OUTOFMEMORY;
		return;
	}
}

//-----------------------------------------------------------------------------

CWavWriterFilter::~CWavWriterFilter()
{
	delete m_pPin;
    delete m_pFileName;
	delete m_pPeakFileName;
	delete[] m_OutBuff;
	delete[] m_ConvBuff;
	delete m_ConvCircBuffer;
}

//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::NonDelegatingQueryInterface(REFIID riid, void ** ppv)
{
    CheckPointer(ppv,E_POINTER);
    CAutoLock lock(&m_Lock);
	
    // Do we have this interface
    if (riid == IID_IFileSinkFilter)
	{
        return GetInterface((IFileSinkFilter *) this, ppv);
    }
	else if (riid == IID_IMediaSeeking)
	{
		return GetInterface((IMediaSeeking *) this, ppv);
	}
	else if (riid == IID_IWavWriter)
	{
		return GetInterface((IWavWriter *)this, ppv);
	}
	
    return CBaseFilter::NonDelegatingQueryInterface(riid, ppv);
}

//-----------------------------------------------------------------------------

CBasePin * CWavWriterFilter::GetPin(int n)
{
    if (n == 0) {
        return m_pPin;
    } else {
        return NULL;
    }
}

//-----------------------------------------------------------------------------

int CWavWriterFilter::GetPinCount()
{
    return 1;
}

//-----------------------------------------------------------------------------

HRESULT CWavWriterFilter::StartWriting()
{
	if(!m_Writting)
	{
		// Get allocator size
		ALLOCATOR_PROPERTIES InProps;
		IMemAllocator * pInAlloc = NULL;		
		HRESULT hr;
		
		hr = m_pPin->GetAllocator(&pInAlloc);
		if(SUCCEEDED(hr))
		{
			hr = pInAlloc->GetProperties(&InProps);
			m_InputAllocatorBuffSize = InProps.cbBuffer;
			pInAlloc->Release();
		}		

		if(m_bWriteWavFile)
		{	
			m_WavFile = new CWAVFileWriter();
			if(!m_WavFile->Init(m_pFileName, m_wf))
			{
				delete m_WavFile;
				m_WavFile = NULL;
				return S_FALSE;
			}

			m_ConvBuffSize = 512 * (m_InputChannels * (m_wf->wBitsPerSample / 8)) * 2 * 2;
			if(m_ConvBuff)
				delete[] m_ConvBuff;
			m_ConvBuff = new char[m_ConvBuffSize];
			
			m_OutBuffSize = max((m_InputAllocatorBuffSize * 2), m_ConvBuffSize);
			if(m_OutBuff)
				delete[] m_OutBuff;
			m_OutBuff = new char[m_OutBuffSize];
			
			if(m_bFastConvertMode)		
			{			
				if(m_ConvCircBuffer)
					delete m_ConvCircBuffer;
				m_ConvCircBuffer = new CircBuffer(max(m_InputAllocatorBuffSize * 2, m_ConvBuffSize * 2));
			}
		}

		InitPeakData();
		m_Writting = true;
	}
	return S_OK;
}

//-----------------------------------------------------------------------------

HRESULT CWavWriterFilter::StopWriting()
{
	if(m_Writting)
	{
		if(m_WavFile)
		{
			if(m_bFastConvertMode)
			{			
				LONG lOutLength = 0;
				Convert(NULL, 0, m_OutBuff, &lOutLength, true);
				PeakProcessing((PBYTE)m_OutBuff, lOutLength, true);
				m_WavFile->WritePCMData(m_OutBuff, lOutLength);
			}
			delete m_WavFile;
			m_WavFile = NULL;
		}
		CleanPeakData();
		m_Writting = false;
	}
	m_cbWavData = 0;
	return S_OK;
}

//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::Stop()
{
    CAutoLock cObjectLock(m_pLock);
	StopWriting();
    return CBaseFilter::Stop();
}

//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::Pause()
{
    CAutoLock cObjectLock(m_pLock);
	StartWriting();
    return CBaseFilter::Pause();
}

//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::Run(REFERENCE_TIME tStart)
{
    CAutoLock cObjectLock(m_pLock);
	StartWriting();
    return CBaseFilter::Run(tStart);
}

//-----------------------------------------------------------------------------

HRESULT CWavWriterFilter::Write(PBYTE pbData, LONG lDataLength)
{
    CAutoLock cObjectLock(m_pLock);

	if(!m_Writting)
		return S_FALSE;

	m_cbWavData += lDataLength;

	if(!m_bFastConvertMode)
		PeakProcessing(pbData, lDataLength, false);

	if(m_WavFile)
	{
		LONG lOutLength = m_OutBuffSize;
		Convert((char*)pbData, lDataLength, m_OutBuff, &lOutLength, false);
		if(m_bFastConvertMode)
			PeakProcessing((PBYTE)m_OutBuff, lOutLength, false);
		if(!m_WavFile->WritePCMData(m_OutBuff, lOutLength))
		{
			return S_FALSE;
		}
	}
	return S_OK;
}

//-----------------------------------------------------------------------------

HRESULT CWavWriterFilter::Convert(char* pInData, long lInLength, char* pOutData, long *lOutLength, bool finalize)
{
	if(m_bFastConvertMode)
	{
		*lOutLength = 0;
		
		if(pInData)
			m_ConvCircBuffer->Write(pInData, lInLength);
		
		int BytesToRead = 0, BytesAvailable = 0;

		while( ((BytesAvailable = m_ConvCircBuffer->Size()) >= m_ConvBuffSize) || finalize)
		{
			if(finalize && (BytesAvailable < m_ConvBuffSize))
			{
				ZeroMemory(m_ConvBuff, m_ConvBuffSize);
				BytesToRead = BytesAvailable;
				finalize = false;
			} else {
				BytesToRead = m_ConvBuffSize;
			}
			
			m_ConvCircBuffer->Read(m_ConvBuff, BytesToRead);

			switch(m_wf->wBitsPerSample)
			{
			case 8:
				{
					char* src = (char*)m_ConvBuff;
					char* dst = (char*)pOutData;
					int i, j;
					int sample;

					i = 0;
					int loop = BytesToRead / sizeof(char) / m_InputChannels / 2;
					while(i < loop)
					{
						// Read and convert one sample to mono
						sample = 0;
						for(j=0; j < m_InputChannels; j++)
							sample += *src++;
						sample /= m_InputChannels;
						// Write the sample
						*dst++ = (char)sample;
						// Skip next sample
						src += m_InputChannels;
						i++;
					}
					*lOutLength = i * sizeof(char);
				}
				break;
				
			case 16:
				{
					short* src = (short*)m_ConvBuff;
					short* dst = (short*)pOutData;
					int i, j;
					int sample1, sample2;

					if ((((BytesToRead / m_InputChannels) / 2) % 2) != 0) {
						i = 0;
					}
					
					i = 0;
					int loop = BytesToRead / sizeof(short) / m_InputChannels / 2;
					while(i < loop)
					{
						// Read and convert one sample to mono
						sample1 = 0;
						for(j=0; j < m_InputChannels; j++)
							sample1 += *src++;
						sample1 /= m_InputChannels;
						/**
						// Read and convert another sample to mono
						sample2 = 0;
						for(j=0; j < m_InputChannels; j++)
							sample2 += *src++;
						sample2 /= m_InputChannels;
						// Write the sample
						*dst++ = (short)((sample1 + sample2) / 2);
						/**/
						
						/**/
						// Skip next sample
						src += m_InputChannels;
						// Write the sample
						*dst++ = (short)sample1;
						/**/

						i++;
					}
					*lOutLength = i * sizeof(short);
				}
				break;
			}
		}
	} else {
		CopyMemory((PVOID) pOutData,(PVOID) pInData, lInLength);		
		*lOutLength = lInLength;
	}
	return S_OK;
}


//-----------------------------------------------------------------------------

HRESULT CWavWriterFilter::InitPeakData()
{
	if(m_bWritePeakFile)
	{	
		m_SamplePerPeak = m_InputSampleRate / m_SamplePerPeakRatio;
		if(m_bFastConvertMode)
			m_SamplePerPeak /= 2;
		
		ZeroMemory(&m_PeakFileHeader, sizeof(m_PeakFileHeader));
		strncpy(m_PeakFileHeader.ID, PeakFileID,8);
		m_PeakFileHeader.SamplePerSec = m_wf->nSamplesPerSec;
		m_PeakFileHeader.Channels = m_wf->nChannels;
		m_PeakFileHeader.BitsPerSample = m_wf->wBitsPerSample;
		m_PeakFileHeader.Version = PeakFileVer;
		m_PeakFileHeader.SamplePerPeak = m_SamplePerPeak;
		m_PeakFile = fopen(m_pPeakFileName, "wb");
		if(!m_PeakFile)
		{
			m_bWritePeakFile = false;
		} else {
			fwrite(&m_PeakFileHeader,1,sizeof(m_PeakFileHeader),m_PeakFile);
			
			if(m_PeakCalcBuffer)
				delete[] m_PeakCalcBuffer;
			m_PeakCalcBufferSize = (m_SamplePerPeak * (m_wf->wBitsPerSample / 8) * m_wf->nChannels);
			m_PeakCalcBuffer = new char[m_PeakCalcBufferSize];
			
			if(m_PeakCircBuffer)
				delete m_PeakCircBuffer;
			m_PeakCircBuffer = new CircBuffer( max(m_InputAllocatorBuffSize * 2, m_PeakCalcBufferSize * 2) );
		}
	}
	return S_OK;
}

//----------------------------------------------------------------------------

void CWavWriterFilter::PeakProcessing(BYTE* pInData, LONG lInLength, bool finalize)
{
	int BytesToRead = 0, BytesAvailable = 0;
	
	if(!m_bWritePeakFile || m_PeakFile == NULL)
		return;
	
	if(pInData != NULL)
		m_PeakCircBuffer->Write(pInData, lInLength);
	
	while( ((BytesAvailable = m_PeakCircBuffer->Size()) >= m_PeakCalcBufferSize) || finalize)
	{
		if(finalize && (BytesAvailable < m_PeakCalcBufferSize))
		{
			ZeroMemory(m_PeakCalcBuffer, m_PeakCalcBufferSize);
			BytesToRead = BytesAvailable;
			finalize = false;
		} else {
			BytesToRead = m_PeakCalcBufferSize;
		}
		
		m_PeakCircBuffer->Read(m_PeakCalcBuffer, BytesToRead);
		
		switch(m_wf->wBitsPerSample)
		{
		case 8:
			{			
				char *src = (char*)m_PeakCalcBuffer;
				m_Peak.Max = -128;
				m_Peak.Min = 127;
				for(unsigned int i = 0; i < BytesToRead / sizeof(char) ; i++)
				{
					if(src[i] > m_Peak.Max)
						m_Peak.Max = src[i];
					if(src[i] < m_Peak.Min)
						m_Peak.Min = src[i];
				}
				m_Peak.Max <<= 16;
				m_Peak.Min <<= 16;
				fwrite(&m_Peak, 1, sizeof(m_Peak), m_PeakFile);
				m_PeakFileHeader.PeakTabLen++;
			}
			break;
		case 16:
			{			
				short *src = (short*)m_PeakCalcBuffer;
				m_Peak.Max = -32768;
				m_Peak.Min = 32767;
				for(unsigned int i = 0; i < BytesToRead / sizeof(short) ; i++)
				{
					if(src[i] > m_Peak.Max)
						m_Peak.Max = src[i];
					if(src[i] < m_Peak.Min)
						m_Peak.Min = src[i];
				}
				fwrite(&m_Peak, 1, sizeof(m_Peak), m_PeakFile);
				m_PeakFileHeader.PeakTabLen++;
			}
			break;
		}
	}
}

//----------------------------------------------------------------------------

void CWavWriterFilter::CleanPeakData()
{
	if(m_PeakFile)
	{
		// Process data left in m_DataBuffer
		PeakProcessing(NULL,0,true);
		// Update length in ms
		double LengthMs = (double)(m_cbWavData / m_InputChannels / (m_wf->wBitsPerSample / 8)) / m_InputSampleRate;
		m_PeakFileHeader.LengthMs = (int)(LengthMs * 1000 + 0.5);
		fseek(m_PeakFile,0,SEEK_SET);
		fwrite(&m_PeakFileHeader, 1, sizeof(m_PeakFileHeader), m_PeakFile);		
		fclose(m_PeakFile);
		delete[] m_PeakCalcBuffer;
		m_PeakCalcBuffer = NULL;
		delete m_PeakCircBuffer;
		m_PeakCircBuffer = NULL;
	}
}

//-----------------------------------------------------------------------------
// IFileSinkFilter
//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::SetFileName(LPCOLESTR pszFileName,const AM_MEDIA_TYPE *pmt)
{
    // Is this a valid filename supplied
	
    CheckPointer(pszFileName,E_POINTER);
    if(wcslen(pszFileName) > MAX_PATH)
        return ERROR_FILENAME_EXCED_RANGE;
	
    // Take a copy of the filename
	
    m_pFileName = new WCHAR[1+lstrlenW(pszFileName)];
    if (m_pFileName == 0)
        return E_OUTOFMEMORY;
	
    lstrcpyW(m_pFileName,pszFileName);
		
    return S_OK;
	
} // SetFileName

//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::GetCurFile(LPOLESTR * ppszFileName, AM_MEDIA_TYPE *pmt)
{
    CheckPointer(ppszFileName, E_POINTER);
    *ppszFileName = NULL;
	
    if (m_pFileName != NULL) 
    {
        *ppszFileName = (LPOLESTR)
			QzTaskMemAlloc(sizeof(WCHAR) * (1+lstrlenW(m_pFileName)));
		
        if (*ppszFileName != NULL) 
        {
            lstrcpyW(*ppszFileName, m_pFileName);
        }
    }
	
    if(pmt) 
    {
        ZeroMemory(pmt, sizeof(*pmt));		
        pmt->majortype = MEDIATYPE_Audio;
        pmt->subtype = MEDIASUBTYPE_PCM;
    }

    return S_OK;
	
} // GetCurFile

// ----------------------------------------------------------------------------
// IMediaSeeking
// ----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::GetCapabilities( DWORD * pCapabilities )
{
    CheckPointer(pCapabilities, E_POINTER);
    *pCapabilities = m_dwSeekingCaps;
    return S_OK;
}

STDMETHODIMP CWavWriterFilter::CheckCapabilities( DWORD * pCapabilities )
{
    CheckPointer(pCapabilities, E_POINTER);
    // make sure all requested capabilities are in our mask
    return (~m_dwSeekingCaps & *pCapabilities) ? S_FALSE : S_OK;
}

STDMETHODIMP CWavWriterFilter::IsFormatSupported(const GUID * pFormat)
{
    CheckPointer(pFormat, E_POINTER);
    // only seeking in time (REFERENCE_TIME units) is supported
    return *pFormat == TIME_FORMAT_MEDIA_TIME ? S_OK : S_FALSE;
}

STDMETHODIMP CWavWriterFilter::QueryPreferredFormat(GUID *pFormat)
{
    CheckPointer(pFormat, E_POINTER);
    *pFormat = TIME_FORMAT_MEDIA_TIME;
    return S_OK;
}

STDMETHODIMP CWavWriterFilter::SetTimeFormat(const GUID * pFormat)
{
    CheckPointer(pFormat, E_POINTER);
    // nothing to set; just check that it's TIME_FORMAT_TIME
    return *pFormat == TIME_FORMAT_MEDIA_TIME ? S_OK : E_INVALIDARG;
}

STDMETHODIMP CWavWriterFilter::IsUsingTimeFormat(const GUID * pFormat)
{
    CheckPointer(pFormat, E_POINTER);
    return *pFormat == TIME_FORMAT_MEDIA_TIME ? S_OK : S_FALSE;
}

STDMETHODIMP CWavWriterFilter::GetTimeFormat(GUID *pFormat)
{
    CheckPointer(pFormat, E_POINTER);
    *pFormat = TIME_FORMAT_MEDIA_TIME;
    return S_OK;
}

STDMETHODIMP CWavWriterFilter::GetDuration(LONGLONG *pDuration)
{
    CheckPointer(pDuration, E_POINTER);
    *pDuration = m_rtDuration;
    return S_OK;
}

STDMETHODIMP CWavWriterFilter::GetCurrentPosition(LONGLONG *pCurrent)
{
    CheckPointer(pCurrent, E_POINTER);

	CMediaType mt;
	m_pPin->ConnectionMediaType(&mt);

	WAVEFORMATEX *wf = NULL;
	if(mt.FormatLength() == sizeof(WAVEFORMATEX))
	{
		wf = (WAVEFORMATEX *)mt.Format();
	} else if(mt.FormatLength() == sizeof(WAVEFORMATEXTENSIBLE)) {
		wf = &((WAVEFORMATEXTENSIBLE*)mt.Format())->Format;
	}
	
	if(wf)
	{		
		*pCurrent = (((LONGLONG)m_cbWavData / wf->nBlockAlign) / wf->nSamplesPerSec) * 10000000;
	} else {
		*pCurrent = 0;
	}
	
    return S_OK;
}

STDMETHODIMP CWavWriterFilter::GetStopPosition(LONGLONG *pStop) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::ConvertTimeFormat(LONGLONG* pTarget, const GUID* pTargetFormat, LONGLONG Source, const GUID* pSourceFormat) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::SetPositions(LONGLONG* pCurrent, DWORD dwCurrentFlags, LONGLONG* pStop, DWORD dwStopFlags) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::GetPositions(LONGLONG* pCurrent, LONGLONG* pStop) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::GetAvailable(LONGLONG* pEarliest, LONGLONG* pLatest) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::SetRate(double dRate) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::GetRate(double* pdRate) { return E_NOTIMPL; }
STDMETHODIMP CWavWriterFilter::GetPreroll(LONGLONG* pllPreroll) { return E_NOTIMPL; }

// ----------------------------------------------------------------------------
// IWavWriter
// ----------------------------------------------------------------------------

STDMETHODIMP CWavWriterFilter::SetFastConversionMode(DWORD FastConvertMode)
{
	m_bFastConvertMode = FastConvertMode ? true : false;
	return S_OK;
}

STDMETHODIMP CWavWriterFilter::GetFastConversionMode(DWORD *FastConvertMode)
{	
	CheckPointer(FastConvertMode, E_POINTER);
	*FastConvertMode = m_bFastConvertMode ? 1 : 0;
	return S_OK;
}

STDMETHODIMP CWavWriterFilter::SetSamplesPerPeakRatio(DWORD SamplePerPeakRatio)
{
	m_SamplePerPeakRatio = SamplePerPeakRatio;
	return S_OK;
}

STDMETHODIMP CWavWriterFilter::SetWritePeakFile(DWORD WritePeakFile)
{
	m_bWritePeakFile = WritePeakFile ? true : false;
	return S_OK;
}

STDMETHODIMP CWavWriterFilter::SetWriteWavFile(DWORD WriteWavFile)
{
	m_bWriteWavFile = WriteWavFile ? true : false;
	return S_OK;
}

STDMETHODIMP CWavWriterFilter::SetPeakFileName(LPCOLESTR pszFileName)
{	
	int cch = lstrlenW(pszFileName) + 1;
	
	if(m_pPeakFileName)
		delete[] m_pPeakFileName;
	
	m_pPeakFileName = new char[cch * 2];
	
	WideCharToMultiByte(GetACP(), 0, pszFileName, -1,
		m_pPeakFileName, cch, NULL, NULL);

	return S_OK;
}

//=============================================================================

CWavWriterInputPin::CWavWriterInputPin(CWavWriterFilter *pFilter,
							 CCritSec *pLock,
                             CCritSec *pReceiveLock,
                             HRESULT *phr) :

    CRenderedInputPin(NAME("CWavWriterInputPin"),
                  pFilter,                   // Filter
                  pLock,                     // Locking
                  phr,                       // Return code
                  L"Input"),                 // Pin name
    m_pReceiveLock(pReceiveLock),
	m_pFilter(pFilter)
{

}

//-----------------------------------------------------------------------------
//
// CheckMediaType
//
// Check if the pin can support this specific proposed type and format
//
HRESULT CWavWriterInputPin::CheckMediaType(const CMediaType *mtIn)
{
    if(mtIn->formattype == FORMAT_WaveFormatEx)
    {
		WAVEFORMATEX *wf = NULL;
		if(mtIn->FormatLength() == sizeof(WAVEFORMATEX))
		{
			wf = (WAVEFORMATEX *)mtIn->Format();
		} else if(mtIn->FormatLength() == sizeof(WAVEFORMATEXTENSIBLE)) {
			wf = &((WAVEFORMATEXTENSIBLE*)mtIn->Format())->Format;
		} else {
			return S_FALSE;
		}
		
		if(wf->wBitsPerSample == 16 || wf->wBitsPerSample == 8)
		{
			return S_OK;
		}
    }
    return S_FALSE;
}

//-----------------------------------------------------------------------------

HRESULT CWavWriterInputPin::CompleteConnect(IPin *pReceivePin)
{
	IMediaSeeking *pIMediaSeeking = NULL;
	HRESULT hr;
	
	// Get duration
	m_pFilter->m_rtDuration = 0;
	hr = pReceivePin->QueryInterface(IID_IMediaSeeking, (void **)&pIMediaSeeking);		
	if(SUCCEEDED(hr))
	{			
		pIMediaSeeking->GetDuration(&m_pFilter->m_rtDuration);
	}
	
	// Keep info on input media type, and set info for output
	pReceivePin->ConnectionMediaType(&m_pFilter->m_OutType);
	
	if(m_pFilter->m_OutType.FormatLength() == sizeof(WAVEFORMATEX))
	{
		m_pFilter->m_wf = (WAVEFORMATEX *)m_pFilter->m_OutType.Format();
	} else if(m_pFilter->m_OutType.FormatLength() == sizeof(WAVEFORMATEXTENSIBLE)) {
		m_pFilter->m_wf = &((WAVEFORMATEXTENSIBLE*)m_pFilter->m_OutType.Format())->Format;
	} else {
		m_pFilter->m_wf = NULL; // not good :>
	}
	
	m_pFilter->m_InputSampleRate = m_pFilter->m_wf->nSamplesPerSec;
	m_pFilter->m_InputChannels = m_pFilter->m_wf->nChannels;

	if(m_pFilter->m_bFastConvertMode)
	{
		m_pFilter->m_wf->nSamplesPerSec /= 2;
		m_pFilter->m_wf->nChannels = 1;
		m_pFilter->m_wf->nBlockAlign = (WORD)((m_pFilter->m_wf->wBitsPerSample / 8) * m_pFilter->m_wf->nChannels);
		m_pFilter->m_wf->nAvgBytesPerSec = m_pFilter->m_wf->nBlockAlign * m_pFilter->m_wf->nSamplesPerSec;
	}

	return CRenderedInputPin::CompleteConnect(pReceivePin);
}

//-----------------------------------------------------------------------------
//
// ReceiveCanBlock
//
// We don't hold up source threads on Receive
//
STDMETHODIMP CWavWriterInputPin::ReceiveCanBlock()
{
    return S_FALSE;
}

//-----------------------------------------------------------------------------
//
// Receive
//
// Do something with this media sample
//
STDMETHODIMP CWavWriterInputPin::Receive(IMediaSample *pSample)
{
    CheckPointer(pSample,E_POINTER);

    CAutoLock lock(m_pReceiveLock);
    PBYTE pbData;

	REFERENCE_TIME rtStart = 0, rtStop = 0;
	pSample->GetTime(&rtStart,&rtStop);

	if((rtStart != m_tPrevStop) &&
		((m_tPrevStart != rtStart) && (m_tPrevStop != rtStop)) &&
		(m_tPrevStop == 0))
	{
		// Hole in timestamps, pad with silent
		double NbSilentSamples = (double)(((rtStart - m_tPrevStop) * m_pFilter->m_InputSampleRate *
			m_pFilter->m_InputChannels) / 10000000);
		int SilentSamplesLen = (int)(NbSilentSamples * (m_pFilter->m_wf->wBitsPerSample / 8));
		SilentSamplesLen += (SilentSamplesLen % (m_pFilter->m_InputChannels * m_pFilter->m_wf->wBitsPerSample / 8));

		PBYTE DummyBuffer = new BYTE[m_pFilter->m_InputAllocatorBuffSize];
		ZeroMemory(DummyBuffer,m_pFilter->m_InputAllocatorBuffSize);
		int toWriteNow = 0;
		while(SilentSamplesLen > 0)
		{
			toWriteNow = min(m_pFilter->m_InputAllocatorBuffSize, SilentSamplesLen);
			m_pFilter->Write(DummyBuffer, toWriteNow);
			SilentSamplesLen -= toWriteNow;
		}
		delete[] DummyBuffer;
	}

	m_tPrevStart = rtStart;
	m_tPrevStop = rtStop;

    // Copy the data to the file
    HRESULT hr = pSample->GetPointer(&pbData);
    if (FAILED(hr)) {
        return hr;
    }
	

    return m_pFilter->Write(pbData, pSample->GetActualDataLength());
}

//-----------------------------------------------------------------------------

STDMETHODIMP CWavWriterInputPin::NewSegment(REFERENCE_TIME tStart,
                                       REFERENCE_TIME tStop,
                                       double dRate)
{
    m_tPrevStart = 0;
	m_tPrevStop = 0;
    return S_OK;
	
} // NewSegment

//-----------------------------------------------------------------------------
//
// EndOfStream
//
STDMETHODIMP CWavWriterInputPin::EndOfStream(void)
{
    CAutoLock lock(m_pReceiveLock);
    return CRenderedInputPin::EndOfStream();

} // EndOfStream

////////////////////////////////////////////////////////////////////////
//
// Exported entry points for registration and unregistration 
// (in this case they only call through to default implementations).
//
////////////////////////////////////////////////////////////////////////

//
// DllRegisterSever
//
// Handle the registration of this filter
//
STDAPI DllRegisterServer()
{
    return AMovieDllRegisterServer2( TRUE );

} // DllRegisterServer


//
// DllUnregisterServer
//
STDAPI DllUnregisterServer()
{
    return AMovieDllRegisterServer2( FALSE );

} // DllUnregisterServer


//
// DllEntryPoint
//
extern "C" BOOL WINAPI DllEntryPoint(HINSTANCE, ULONG, LPVOID);

BOOL APIENTRY DllMain(HANDLE hModule, 
                      DWORD  dwReason, 
                      LPVOID lpReserved)
{
	return DllEntryPoint((HINSTANCE)(hModule), dwReason, lpReserved);
}

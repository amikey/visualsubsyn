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

// Very simple circular buffer, should never be filled completely :p

class CircBuffer
{
private:
	char* m_Data;
	int m_Size;
	int m_ReadPos;
	int m_WritePos;
	
public:
	CircBuffer(int Size)
	{
		m_Data = new char[Size];
		m_Size = Size;
		m_ReadPos = m_WritePos = 0;
	}

	~CircBuffer()
	{
		delete[] m_Data;
	}
	
	unsigned int Left()
	{
		if(m_WritePos >= m_ReadPos)
			return m_Size - m_WritePos + m_ReadPos;
		else 
			return m_ReadPos - m_WritePos;
	}
	
	unsigned int Size()
	{
		if(m_WritePos >= m_ReadPos)
			return m_WritePos - m_ReadPos;
		else
			return m_Size - m_ReadPos + m_WritePos;
	}
	
	void Write(void* Buffer, int Len)
	{
		int BytesContiguousLeft = 0;
		if(m_WritePos >= m_ReadPos)
			BytesContiguousLeft = m_Size - m_WritePos;
		else
			BytesContiguousLeft = m_ReadPos - m_WritePos;
		
		int BytesFirstPart = min(BytesContiguousLeft, Len);
		memcpy(&m_Data[m_WritePos], Buffer, BytesFirstPart);
		m_WritePos = (m_WritePos + BytesFirstPart) % m_Size;
		
		int BytesSecondPart = Len - BytesFirstPart;
		if(BytesSecondPart)
		{
			memcpy(&m_Data[m_WritePos], (char*)Buffer+BytesFirstPart, BytesSecondPart);
			m_WritePos = (m_WritePos + BytesSecondPart) % m_Size;
		}
	}
	
	void Read(void* Buffer, int Len)
	{
		int BytesContiguous = 0;
		if(m_WritePos >= m_ReadPos)
			BytesContiguous = m_WritePos - m_ReadPos;
		else
			BytesContiguous = m_Size - m_ReadPos;
		
		int BytesFirstPart = min(BytesContiguous, Len);
		memcpy(Buffer, &m_Data[m_ReadPos], BytesFirstPart);
		m_ReadPos = (m_ReadPos + BytesFirstPart) % m_Size;
		
		int BytesSecondPart = Len - BytesFirstPart;
		if(BytesSecondPart)
		{
			memcpy((char*)Buffer+BytesFirstPart, &m_Data[m_ReadPos], BytesSecondPart);
			m_ReadPos = (m_ReadPos + BytesSecondPart) % m_Size;
		}
	}

	void Clear()
	{
		m_ReadPos = m_WritePos = 0;
	}
};
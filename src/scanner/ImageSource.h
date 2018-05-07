/*
The MIT License (MIT)

Copyright (c) 2018 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#ifndef BARCODE_IMAGESOURCE_H
#define BARCODE_IMAGESOURCE_H

#include <QImage>
#include <zxing/LuminanceSource.h>
#include <zxing/common/Array.h>

class ImageSource : public zxing::LuminanceSource
{
    Q_DISABLE_COPY(ImageSource)

public:
    ImageSource(QImage aImage);
    ~ImageSource();
    
    QImage grayscaleImage() const;

    zxing::ArrayRef<zxing::byte> getRow(int aY, zxing::ArrayRef<zxing::byte> aRow) const Q_DECL_OVERRIDE;
    zxing::ArrayRef<zxing::byte> getMatrix() const Q_DECL_OVERRIDE;

private:
    const zxing::byte* getGrayRow(int aY) const;

private:
    QImage iImage;
    mutable zxing::byte** iGrayRows;
    mutable zxing::ArrayRef<zxing::byte> iGrayImage;
};

#endif // BARCODE_IMAGESOURCE_H


%mcode to create a mif file
    src = imread('80x60.JPG');

    [m,n,c] = size( src ); %size od your picture
    N = m*n; %your ram or rom depth。

    word_len = 12; 

    fid=fopen('gray_image.mif', 'w'); % open mif file 
    fprintf(fid, 'DEPTH=%d;\n', N);
    fprintf(fid, 'WIDTH=%d;\n', word_len);

    fprintf(fid, 'ADDRESS_RADIX = UNS;\n'); 
    fprintf(fid, 'DATA_RADIX = HEX;\n'); 
    fprintf(fid, 'CONTENT\t');
    fprintf(fid, 'BEGIN\n');
    i = 0;
    
for x = 1:n
    for y = 1:m
        % Get RGB values
        pixel = src(y, x, :); % covert to decimal then divide and multiply then round the convert to uint8 or uint4
        Dub_pixel = double(pixel);
        Norm_pixel = round((Dub_pixel./255).*15);
        Int8_pixel = uint8(Norm_pixel);
        % Convert each color channel to 12-bit range
        % HEX_RGB = dec2hex(pixel,3); %specify size of HEX_RGB and then arrange data from reshape
        fprintf(fid, '\t%d\t:\t%x%x%x\n',i, Int8_pixel(:,:,1),Int8_pixel(:,:,2),Int8_pixel(:,:,3));
        i = i + 1;
        
    end
end

    fprintf(fid, 'END;\n'); % prinf the end
    fclose(fid); % close your file
function grain
    clc;
    iv = 'absolute';
    key = 'california';
    disp('Grain Chipher');
    disp('-------------');
    message = input('Masukan pesan : ', 's');
    
    % buat array LFSR dan NFSR dengan default nilai 1
    lfsr = ones(1, 80, 'uint32');
    nfsr = ones(1, 80, 'uint32');

    % cetak iv, key, dan message
    disp(['IV: ', iv]);
    disp(['Key: ', key]);
    disp(['Message: ', message]);
    
    % LFSR -> IV
    result = stringToBinary(iv); % iv
    % konversi array result kedalam satu baris array
    index = 1;
    for i = 1:size(result)
        str_result = num2str(result(i));
        for j = 1: 8 % binary 8
            if(j == 1)
                lfsr(index) = 0;
            else
                lfsr(index) = str2num(str_result(j-1));
            end
            index = index+1;
        end
    end
    
    % NFSR -> KEY
    result2 = stringToBinary(key); % key
    % konversi array results kedalam satu baris array
    index = 1;
    for i = 1:size(result2)
        str_result = num2str(result2(i));
        for j = 1: 8
            if(j == 1)
                nfsr(index) = 0;
            else
                nfsr(index) = str2num(str_result(j-1));
            end
            index = index+1;
        end
    end
    
   [filter_array, keystream] = filter(nfsr, lfsr);
   disp(['Keystream: ', keystream]);
   
   cipher = encrypt(message, filter_array);
   disp(['CipherText: ', cipher]);
   
   plain = decrypt(cipher, keystream);
   disp(['Plain: ', plain]);
end

function string = encrypt(message, filter)
    % konversi pesan kedalam string biner
    result = stringToBinary(message);
    % siapkan aray perhitungan sesuai dengan keseluruhan panjang biner
    result_raw_array = zeros(1, length(message)*8);
    result_xor_array = zeros(1, length(message)*8);
    
    % konversi array biner kedalam satu baris array
    index = 1;
    for i = 1:size(result)
        str_result = num2str(result(i));
        for j = 1: 8
            if(j == 1)
                result_raw_array(index) = 0;
            else
                result_raw_array(index) = str2num(str_result(j-1));
            end
            index = index+1;
        end
    end
    
    for i = 1:length(result_raw_array)
        result_xor_array(i) = bitxor(filter(i), result_raw_array(i));
    end
    string = binaryVectorToHex(result_xor_array);
end

function string = decrypt(cipher, keystream)
    cipher_array = hexToBinaryVector(cipher);
    keystream_array = hexToBinaryVector(keystream);
    results = zeros(1, length(cipher_array));
    
    for i = 1:length(cipher_array)
        results(i) = bitxor( cipher_array(i), keystream_array(i) );
    end
    
    plain = '';
    index = 1;
    for i = 1:length(results)/8
        temp = '';
        for j = index:index+7
            temp = strcat(temp, num2str(results(j)));
        end
        index = index+8;
        plain = strcat(char(plain), char(bin2dec(temp)));
    end
    string = plain;
end

function [filter, keystream] = filter(nfsr, lfsr)
    lfsr = sum_lfsr(lfsr);
    nfsr = sum_nfsr(nfsr);
    % array filter
    filter = zeros(1, 160);
    
    x0 = lfsr(3+1);
    x1 = lfsr(25+1);
    x2 = lfsr(46+1);
    x3 = lfsr(64+1);
    x4 = nfsr(63+1);
   
    xor_1 = bitxor(x1, x4);
    xor_2 = bitxor( xor_1, bitand(x0, x3));
    xor_3 = bitxor( xor_2, bitand(x2, x3));
    xor_4 = bitxor( xor_3, bitand(x3, x3));
    xor_5 = bitxor( xor_4, bitand( bitand(x0, x1), x2) );
    xor_6 = bitxor( xor_5, bitand( bitand(x0, x2), x3) );
    xor_7 = bitxor( xor_6, bitand( bitand(x0, x2), x4) );
    xor_8 = bitxor( xor_7, bitand( bitand(x1, x2), x4) );
    f_h = bitxor( xor_8, bitand( bitand(x2, x3), x4) );
    
    for i = 1:160
        filter(i) = bitxor(nfsr(i), f_h);
    end

    keystream = binaryVectorToHex(filter);
end

function lfsr = sum_lfsr(array)
    data = array;
    temp_lfsr = [];
    
    for i = 2:160+1
        xor_1 = bitxor(data(62+1), data(51+1));
        xor_2 = bitxor(xor_1, data(38+1));
        xor_3 = bitxor(xor_2, data(23+1));
        xor_4 = bitxor(xor_3, data(13+1));
        xor =  bitxor(xor_4, data(0+1));
        data = circshift(data, [1, 1]); % rotate array
        temp_lfsr(i-1) = data(1);
        data(1) = xor;
    end
    lfsr = temp_lfsr;
end

function nfsr = sum_nfsr(array)
    data = array;
    temp_nfsr = [];
    
    for i = 2:160+1
        xor_1 = bitxor( bitxor(data(0+1), data(63+1)), data(60+1) );
        xor_2 = bitxor( xor_1, bitxor( bitxor(data(52+1), data(45+1)), data(37+1) ));
        xor_3 = bitxor( xor_2, bitxor( bitxor(data(33+1), data(28+1)), data(21+1) ));
        xor_4 = bitxor( xor_3, bitxor( bitxor(data(15+1), data(19+1)), data(0+1) ));
        xor_5 = bitxor( xor_4, bitxor( bitand(data(63+1), data(60+1)), bitand(data(37+1), data(33+1)) ));
        xor_6 = bitxor( xor_5, bitxor( bitand(data(15+1), data(9+1)), bitand(data(60+1), bitand(data(52+1), data(45+1))) ));
        xor_7 = bitxor( xor_6, bitand( data(33+1), bitand(data(28+1), data(21+1)) ));
        xor_8 = bitxor( xor_7, bitand( bitand(data(63+1), data(45+1)), bitand(data(28+1), data(9+1)) ));
        xor_9 = bitxor( xor_8, bitand( bitand(data(60+1), data(52+1)), bitand(data(37+1), data(33+1)) ));
        xor_10 = bitxor( xor_9, bitand( bitand(data(63+1), data(60+1)), bitand(data(21+1), data(15+1)) ));
        xor_11 = bitxor( xor_10, bitand( bitand(data(63+1), data(60+1)), bitand(bitand(data(52+1), data(45+1)), data(37+1)) ));
        xor_12 = bitxor( xor_11, bitand( bitand(data(33+1), data(28+1)), bitand(bitand(data(21+1), data(15+1)), data(9+1)) ));
        xor = bitxor( xor_12, bitand( bitand(data(52+1), data(45+1)), bitand( bitand(data(37+1), data(33+1)), bitand(data(28+1), data(21+1))) ));
        
        data = circshift(data, [1, 1]); % rotate array
        temp_nfsr(i-1) = data(1);
        data(1) = xor;
    end
    %disp(temp_nfsr)
    nfsr = temp_nfsr;
end

function binary = stringToBinary(string)
    a = double(string);
    b = dec2bin(a);
    binary = str2num(b);
end

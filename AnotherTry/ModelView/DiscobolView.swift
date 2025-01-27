//
//  DiscobolView.swift
//  AnotherTry
//
//  Created by Nurbol on 05.12.2022.
//

import SwiftUI

struct DiscobolView: View {
    var body: some View {
        ScrollView{
            VStack {
                Image("Discobol")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 450, height: 230)
                    .shadow(radius: 8)
                
                Text("«Дискобол» – это одна из самых известных скульптур времен Античности. Кроме того, это первая скульптура, которая изображает человека в движении. На то время передать такие сложные движения в скульптуре было очень сложно. Возраст этой скульптуры – около двух с половиной тысяч лет. Оригинал этой статуи на сегодняшний день не сохранился, поэтому мы можем видеть только лишь копии. Они сделаны в период существования Римской империи. Известно, что оригинальная скульптура «Дискобола» была утеряна в период Средних веков.")
                    .padding(20)
                    .padding(.horizontal)
                    .lineLimit(nil)
                
                Text("Статуя изображает метателя диска в момент размаха перед броском. Фигура прославляет древнегреческих метателей диска. Мы видим обнаженного юношу, который наклонился вперед, метая диск. Его рука, метающая диск, напряжена и отведена до предела. Готовность к движению скульптор изобразил в этой фигуре: кажется, юноша вот-вот бросит с огромной силой диск, и он полетит на далекое расстояние.")
                    .padding(20)
                    .padding(.horizontal)
                    .lineLimit(nil)
                
                Button(action: {
                    
                }, label: {
                    Text("Перейти в AR режим")
                        .padding()
                })
            }
        }
    }
}

struct DiscobolView_Previews: PreviewProvider {
    static var previews: some View {
        DiscobolView()
    }
}
